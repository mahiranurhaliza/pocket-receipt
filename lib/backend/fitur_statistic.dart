import 'package:flutter/material.dart';

import '../UI/statistic.dart' as ui;
import 'fitur_portfolio.dart';

Color expenseColor(String name) =>
    const <String, Color>{
      'BNI': Color(0xFFC7E212),
      'OVO': Color(0xFF793ECC),
      'Cash': Color(0xFF5C5C5C),
      'Gopay': Color(0xFF00AED6),
      'Shopeepay': Color(0xFFFF6135),
      'Bills': Color(0xFFFFED7E),
      'Top-ups': Color(0xFFD2BFEE),
      'Food & Beverages': Color(0xFFFF9FC6),
      'Transportation': Color(0xFFFFB870),
      'Shopping': Color(0xFF70E5F2),
    }[name] ??
    Colors.blueGrey;

class AnalyticsLoader extends StatefulWidget {
  final Widget Function(BuildContext, List<ReceiptRecord>) builder;

  const AnalyticsLoader({super.key, required this.builder});

  @override
  State<AnalyticsLoader> createState() => _AnalyticsLoaderState();
}

class _AnalyticsLoaderState extends State<AnalyticsLoader> {
  late Future<List<ReceiptRecord>> _future;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
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
    final nextFuture = Future.sync(
      () => AnalyticsSource.repository.fetch(AnalyticsSource.userId),
    );
    if (notify && mounted) {
      setState(() => _future = nextFuture);
    } else {
      _future = nextFuture;
    }
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
          return widget.builder(context, snapshot.data ?? const []);
        },
      );
}

/// Six weeks ending in the current week; future transactions excluded.
class StatisticSnapshot {
  StatisticSnapshot(Iterable<ReceiptRecord> records, DateTime now)
      : weeks = List.unmodifiable(
          ReceiptAnalytics.weeks(
            records.where((r) => !r.date.isAfter(now)),
            now,
          ),
        );

  final List<ExpenseGroup> weeks;

  int get total => weeks.last.total;

  Map<DateTime, List<ReceiptRecord>> get days =>
      ReceiptAnalytics.daily(weeks.last.records);

  double get maxValue {
    final max = weeks.fold<int>(0, (m, g) => g.total > m ? g.total : m);
    return max == 0 ? 40000.0 : (max / 40000).ceil() * 40000.0;
  }
}

/// Loads and calculates statistics from the database before invoking the screen.
class FiturStatistic extends StatefulWidget {
  const FiturStatistic({
    super.key,
    this.repository,
    this.userId,
    this.onCalculated,
  });

  final ReceiptRepository? repository;
  final String? userId;
  final ValueChanged<StatisticSnapshot>? onCalculated;

  @override
  State<FiturStatistic> createState() => _FiturStatisticState();
}

class _FiturStatisticState extends State<FiturStatistic> {
  late Future<StatisticSnapshot> _future;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
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
    final nextFuture = Future.sync(() async {
      final records = await repository.fetch(userId);
      final data = StatisticSnapshot(records, DateTime.now());
      if (mounted) widget.onCalculated?.call(data);
      return data;
    });

    if (notify && mounted) {
      setState(() => _future = nextFuture);
    } else {
      _future = nextFuture;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StatisticSnapshot>(
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

          final data = snapshot.data!;
          final dayCards = data.days.entries.map((entry) {
            final d = entry.key.toLocal();
            return ui.StatisticDayItem(
              dateLabel: dateLabel(d),
              transactions: entry.value
                  .map(
                    (r) => ui.StatisticTransactionItem(
                      merchant: r.merchant,
                      amountText: rupiah(r.amount),
                      source: r.pocket,
                      color: expenseColor(r.pocket),
                    ),
                  )
                  .toList(),
            );
          }).toList();

          return ui.StatisticScreen(
            totalExpense: rupiah(data.total),
            maxValue: data.maxValue,
            dayCards: dayCards,
          );
        },
      );
}