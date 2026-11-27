import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../database/receipt_model.dart';
import '../UI/portfolio.dart' as ui;
import 'fitur_statistic.dart';

/// Database-independent analytics. Amounts are integer Indonesian rupiah.
class ReceiptRecord {
  final String id, userId, merchant, pocket, category;
  final DateTime date;
  final int amount;

  ReceiptRecord({
    required this.id,
    required this.userId,
    required this.merchant,
    required this.pocket,
    required this.category,
    required this.date,
    required this.amount,
  }) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount');
  }

  static ReceiptRecord fromReceiptModel(
    ReceiptModel model, {
    String userId = 'local',
  }) {
    final safeAmount = model.totalAmount.isFinite && model.totalAmount > 0
        ? model.totalAmount.round()
        : 0;
    final idStr = model.id?.toString() ??
        '${model.date.microsecondsSinceEpoch}_${model.storeName.hashCode}';

    return ReceiptRecord(
      id: idStr,
      userId: userId,
      merchant:
          model.storeName.trim().isEmpty ? 'Merchant' : model.storeName.trim(),
      pocket: model.sourceOfFunds.trim().isEmpty
          ? 'Cash'
          : model.sourceOfFunds.trim(),
      category: model.category.trim().isEmpty
          ? 'Uncategorized'
          : model.category.trim(),
      date: model.date.toLocal(),
      amount: safeAmount,
    );
  }
}

abstract class ReceiptRepository {
  Future<List<ReceiptRecord>> fetch(String userId);
}

class MemoryReceiptRepository implements ReceiptRepository {
  final List<ReceiptRecord> _records;

  MemoryReceiptRepository(Iterable<ReceiptRecord> records)
      : _records = List.of(records);

  @override
  Future<List<ReceiptRecord>> fetch(String userId) async =>
      _records.where((r) => r.userId == userId).toList();

  void upsert(ReceiptRecord record) {
    _records.removeWhere((r) => r.id == record.id && r.userId == record.userId);
    _records.add(record);
  }

  void delete(String userId, String id) =>
      _records.removeWhere((r) => r.userId == userId && r.id == id);
}

class DatabaseReceiptRepository implements ReceiptRepository {
  DatabaseReceiptRepository({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  final DatabaseService _db;

  @override
  Future<List<ReceiptRecord>> fetch(String userId) async {
    final receipts = await _db.getAllReceipts();
    return receipts
        .map((r) => ReceiptRecord.fromReceiptModel(r, userId: userId))
        .toList();
  }
}

class ExpenseGroup {
  final String name;
  final List<ReceiptRecord> records;

  ExpenseGroup(this.name, Iterable<ReceiptRecord> records)
      : records = List.unmodifiable(records);

  int get total => ReceiptAnalytics.total(records);
  int get count => records.length;
}

class ReceiptAnalytics {
  static DateTime day(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static DateTime shift(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static DateTime monday(DateTime d) => shift(day(d), 1 - day(d).weekday);

  static int total(Iterable<ReceiptRecord> records) =>
      records.fold(0, (sum, r) => sum + r.amount);

  static List<ReceiptRecord> range(
    Iterable<ReceiptRecord> records,
    DateTime start,
    DateTime end,
  ) =>
      records
          .where((r) => !r.date.isBefore(start) && r.date.isBefore(end))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  static List<ExpenseGroup> groups(
    Iterable<ReceiptRecord> records, {
    required bool byPocket,
  }) {
    final map = <String, List<ReceiptRecord>>{};
    for (final r in records) {
      final name = (byPocket ? r.pocket : r.category).trim();
      (map[name.isEmpty ? 'Uncategorized' : name] ??= []).add(r);
    }
    return map.entries.map((e) => ExpenseGroup(e.key, e.value)).toList()
      ..sort((a, b) {
        final c = b.total.compareTo(a.total);
        return c == 0 ? a.name.compareTo(b.name) : c;
      });
  }

  static Map<DateTime, List<ReceiptRecord>> daily(
    Iterable<ReceiptRecord> records,
  ) {
    final sorted = records.toList()..sort((a, b) => b.date.compareTo(a.date));
    final result = <DateTime, List<ReceiptRecord>>{};
    for (final r in sorted) {
      (result[day(r.date)] ??= []).add(r);
    }
    return result;
  }

  static List<ExpenseGroup> weeks(
    Iterable<ReceiptRecord> records,
    DateTime now,
  ) {
    final current = monday(now);
    return List.generate(6, (i) {
      final start = shift(current, (i - 5) * 7);
      final end = shift(start, 7);
      return ExpenseGroup(
        '${start.day}-${shift(end, -1).day}',
        range(records, start, end),
      );
    });
  }
}

String rupiah(int n) =>
    'Rp${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

const monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String dateLabel(DateTime d) => '${d.day} ${monthNames[d.month - 1]} ${d.year}';

/// Reads from local database (`pocket_receipt.db`) by default.
class AnalyticsSource {
  static String userId = 'local';
  static ReceiptRepository repository = DatabaseReceiptRepository();
}

/// Controller-facing monthly snapshot, independent of the original UI.
class PortfolioSnapshot {
  PortfolioSnapshot(this.period, Iterable<ReceiptRecord> all)
      : records = List.unmodifiable(
          ReceiptAnalytics.range(
            all,
            DateTime(period.year, period.month),
            DateTime(period.year, period.month + 1),
          ),
        );

  final DateTime period;
  final List<ReceiptRecord> records;

  int get total => ReceiptAnalytics.total(records);
  List<ExpenseGroup> get pockets => ReceiptAnalytics.groups(records, byPocket: true);
  List<ExpenseGroup> get categories =>
      ReceiptAnalytics.groups(records, byPocket: false);

  String get label =>
      '1 ${monthNames[period.month - 1]}-${dateLabel(DateTime(period.year, period.month + 1, 0))}';
}

/// Entry point: navigate here instead of directly to PortfolioScreen.
class FiturPortfolio extends StatefulWidget {
  const FiturPortfolio({
    super.key,
    this.repository,
    this.userId,
    this.initialPeriod,
  });

  final ReceiptRepository? repository;
  final String? userId;
  final DateTime? initialPeriod;

  @override
  State<FiturPortfolio> createState() => _FiturPortfolioState();
}

class _FiturPortfolioState extends State<FiturPortfolio> {
  late DateTime _period;
  late Future<List<ReceiptRecord>> _future;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final date = widget.initialPeriod ?? DateTime.now();
    _period = DateTime(date.year, date.month);
    _load(notify: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      return;
    }
    _load(notify: true);
  }

  void _load({bool notify = true}) {
    final repository = widget.repository ?? AnalyticsSource.repository;
    final userId = widget.userId ?? AnalyticsSource.userId;
    final nextFuture = Future.sync(() => repository.fetch(userId));
    if (notify && mounted) {
      setState(() => _future = nextFuture);
    } else {
      _future = nextFuture;
    }
  }

  void _move(int offset) => setState(() {
        _period = DateTime(_period.year, _period.month + offset);
      });

  List<ui.PortfolioDisplayItem> _toDisplayItems(List<ExpenseGroup> groups) {
    return groups
        .map(
          (g) => ui.PortfolioDisplayItem(
            name: g.name,
            amount: rupiah(g.total),
            numericValue: g.total.toDouble(),
            transactions: 'From ${g.count} transactions',
            color: expenseColor(g.name),
          ),
        )
        .toList();
  }

  void _seeAll(PortfolioSnapshot data, String name) {
    final groups = [...data.pockets, ...data.categories]
        .where((g) => g.name == name);
    final matches = <String, ReceiptRecord>{};
    for (final group in groups) {
      for (final record in group.records) {
        matches[record.id] = record;
      }
    }
    final records = matches.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(name),
              subtitle: Text(rupiah(ReceiptAnalytics.total(records))),
            ),
            Expanded(
              child: records.isEmpty
                  ? const Center(child: Text('No transactions in this period'))
                  : ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, i) {
                        final r = records[i];
                        return ListTile(
                          title: Text(r.merchant),
                          subtitle: Text(dateLabel(r.date.toLocal())),
                          trailing: Text(rupiah(r.amount)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ReceiptRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to load transactions'),
                    TextButton(
                      onPressed: () => _load(notify: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = PortfolioSnapshot(
            _period,
            snapshot.data ?? const <ReceiptRecord>[],
          );
          return ui.PortfolioScreen(
            period: data.label,
            expenses: rupiah(data.total),
            categories: _toDisplayItems(data.categories),
            pockets: _toDisplayItems(data.pockets),
            onPreviousPeriod: () => _move(-1),
            onNextPeriod: () => _move(1),
            onSeeAll: (name) => _seeAll(data, name),
          );
        },
      );
}