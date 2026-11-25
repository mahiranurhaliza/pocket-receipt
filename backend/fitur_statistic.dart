import 'package:flutter/material.dart';
import 'fitur_portfolio.dart';
import '../UI/statistic.dart' as ui;

Color expenseColor(String name) => const <String,Color>{
  'BNI':Color(0xFFC7E212),'OVO':Color(0xFF793ECC),'Cash':Color(0xFF5C5C5C),
  'Gopay':Color(0xFF00AED6),'Shopeepay':Color(0xFFFF6135),
  'Bills':Color(0xFFFFED7E),'Top-ups':Color(0xFFD2BFEE),
  'Food & Beverages':Color(0xFFFF9FC6),'Transportation':Color(0xFFFFB870),'Shopping':Color(0xFF70E5F2),
}[name] ?? Colors.blueGrey;

class AnalyticsLoader extends StatefulWidget {
  final Widget Function(BuildContext,List<ReceiptRecord>) builder;
  const AnalyticsLoader({super.key,required this.builder});
  @override State<AnalyticsLoader> createState()=>_AnalyticsLoaderState();
}
class _AnalyticsLoaderState extends State<AnalyticsLoader> {
  late Future<List<ReceiptRecord>> _future;
  @override void initState(){super.initState(); _load();}
  void _load(){_future=Future.sync(()=>AnalyticsSource.repository.fetch(AnalyticsSource.userId));}
  @override Widget build(BuildContext context)=>FutureBuilder<List<ReceiptRecord>>(
    future:_future,builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done) return const Scaffold(body:Center(child:CircularProgressIndicator()));
      if(snapshot.hasError) return Scaffold(appBar:AppBar(),body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Unable to load transactions'),TextButton(onPressed:()=>setState(_load),child:const Text('Retry'))])));
      return widget.builder(context,snapshot.data ?? []);
    });
}


/// Six weeks ending in the current week; future transactions excluded.
class StatisticSnapshot {
  StatisticSnapshot(Iterable<ReceiptRecord> records, DateTime now)
      : weeks = List.unmodifiable(ReceiptAnalytics.weeks(
          records.where((r) => !r.date.isAfter(now)), now));
  final List<ExpenseGroup> weeks;
  int get total => weeks.last.total;
  Map<DateTime, List<ReceiptRecord>> get days => ReceiptAnalytics.daily(weeks.last.records);
  double get maxValue {
    final max = weeks.fold<int>(0, (m, g) => g.total > m ? g.total : m);
    return max == 0 ? 40000.0 : (max / 40000).ceil() * 40000.0;
  }
}

/// Loads and calculates statistics before invoking the original screen.
/// onCalculated exposes the result to the caller; the original screen has
/// no constructor parameters to display it. No UI internals are modified.
class FiturStatistic extends StatefulWidget {
  const FiturStatistic({super.key, this.repository, this.userId, this.onCalculated});
  final ReceiptRepository? repository;
  final String? userId;
  final ValueChanged<StatisticSnapshot>? onCalculated;
  @override
  State<FiturStatistic> createState() => _FiturStatisticState();
}

class _FiturStatisticState extends State<FiturStatistic> {
  late Future<StatisticSnapshot> _future;
  @override
  void initState() {
    super.initState();
    _load();
  }
  void _load() {
    final repository = widget.repository ?? AnalyticsSource.repository;
    final userId = widget.userId ?? AnalyticsSource.userId;
    _future = Future.sync(() async {
      final records = await repository.fetch(userId);
      final data = StatisticSnapshot(records, DateTime.now());
      if (mounted) widget.onCalculated?.call(data);
      return data;
    });
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<StatisticSnapshot>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(appBar: AppBar(), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Unable to load transactions'),
          TextButton(onPressed: () => setState(_load), child: const Text('Retry')),
        ])));
      }
      // The calculation is available via snapshot.data / onCalculated,
      // but StatisticScreen cannot consume it without a public data API.
      return const ui.StatisticScreen();
    },
  );
}
