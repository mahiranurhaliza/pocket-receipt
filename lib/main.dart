
import 'package:flutter/material.dart';
import 'backend/fitur_portfolio.dart';
import 'backend/fitur_statistic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Receipt - Feature Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Bricolage Grotesque',
        scaffoldBackgroundColor: const Color(0xFFDDDDDD),
      ),
      home: const FeatureMenu(),
    );
  }
}

class FeatureMenu extends StatelessWidget {
  const FeatureMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Receipt'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.receipt_long,
                size: 80,
              ),
              const SizedBox(height: 20),

              const Text(
                'Feature Testing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Portfolio & Statistics',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Memanggil fitur Portfolio
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB357),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(200, 55),
                ),
                icon: const Icon(Icons.pie_chart_outline),
                label: const Text('Portfolio'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const FiturPortfolio(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              // Memanggil fitur Statistics
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB696E3),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(200, 55),
                ),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Statistics'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const FiturStatistic(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
