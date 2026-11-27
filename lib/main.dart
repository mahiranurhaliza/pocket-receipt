import 'package:flutter/material.dart';

import 'database/database_service.dart';
import 'fitur_history/history_feature_page.dart';
import 'backend/fitur_portfolio.dart';
import 'fitur_scan/scan_feature_page.dart';
import 'backend/fitur_statistic.dart';
import 'UI/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database;
  runApp(const PocketReceiptApp());
}

class PocketReceiptApp extends StatelessWidget {
  const PocketReceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pocket Receipt',
      theme: ThemeData(
        fontFamily: 'Bricolage Grotesque',
      ),
      home: Builder(
        builder: (context) => HomeScreen(
          onHistory: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const HistoryFeaturePage(),
              ),
            );
          },
          onScan: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ScanFeaturePage(),
              ),
            );
          },
          onPortfolio: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FiturPortfolio(),
              ),
            );
          },
          onStatistic: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FiturStatistic(),
              ),
            );
          },
        ),
      ),
    );
  }
}