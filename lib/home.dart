import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'history.dart';
import 'portfolio.dart';
//import 'scan.dart';
import 'statistic.dart';

// void main() {
//   runApp(
//     const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: HomeScreen(),
//     ),
//   );
// }

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.userName = 'You',
    this.period = '1 Sep-30 Sep 2026',
    this.expenses = 'Rp1.000.000',
    this.onProfile,
    this.onPortfolio,
    this.onStatistic,
    this.onHistory,
    this.onScan,
  });

  final String userName;
  final String period;
  final String expenses;
  final VoidCallback? onProfile;
  final VoidCallback? onPortfolio;
  final VoidCallback? onStatistic;
  final VoidCallback? onHistory;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDDDDD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pageHeight = constraints.maxHeight < 900
              ? 900.0
              : constraints.maxHeight;
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 440.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;
          final tileGap = contentWidth >= 355 ? 25.0 : 16.0;
          final tileWidth = (contentWidth - tileGap) / 2;

          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              height: pageHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // --- BACKGROUND RADIAL GRADIENT RESPONSIF ---
                  // Gradien Kuning
                  Positioned(
                    left: constraints.maxWidth * 0.45,
                    top: -34,
                    child: Container(
                      width: constraints.maxWidth * 0.7,
                      height: constraints.maxWidth * 0.7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Color(0xFFFFEC5C),
                            Color(0x00FFEC5C),
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Gradien Oranye
                  Positioned(
                    left: constraints.maxWidth * 0.05,
                    top: -9,
                    child: Container(
                      width: constraints.maxWidth * 0.7,
                      height: constraints.maxWidth * 0.7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Color(0xFFFFB357),
                            Color(0x00FFB357),
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Gradien Ungu
                  Positioned(
                    left: -constraints.maxWidth * 0.2,
                    top: -63,
                    child: Container(
                      width: constraints.maxWidth * 0.7,
                      height: constraints.maxWidth * 0.7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Color(0xFFB696E3),
                            Color(0x00B696E3),
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // ---------------------------------------------

                  Positioned(
                    width: constraints.maxWidth,
                    height: pageHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x55F8F8F8), 
                      ),
                    ),
                  ),

                  Positioned(
                    top: 55,
                    left: contentLeft + 5,
                    child: const _AppLogo(),
                  ),
                  Positioned(
                    top: 125,
                    left: contentLeft,
                    width: contentWidth,
                    child: _ProfileCard(
                      userName: userName,
                      onPressed: onProfile,
                    ),
                  ),
                  Positioned(
                    top: 220,
                    left: contentLeft,
                    width: contentWidth,
                    child: _InsightsCard(
                      period: period,
                      expenses: expenses,
                    ),
                  ),
                  Positioned(
                    top: 345,
                    left: contentLeft,
                    width: tileWidth,
                    child: _DashboardTile(
                      label: 'Portfolio',
                      asset: 'assets/icons/portfolio.svg',
                      assetWidth: 100,
                      assetHeight: 100,
                      gradientColor: const Color(0xFFFFF185),
                      onPressed: onPortfolio ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PortfolioScreen(),
                              ),
                            );
                          },
                    ),
                  ),
                  Positioned(
                    top: 345,
                    left: contentLeft + tileWidth + tileGap,
                    width: tileWidth,
                    child: _DashboardTile(
                      label: 'Statistic',
                      asset: 'assets/icons/statistic.svg',
                      assetWidth: 100,
                      assetHeight: 100,
                      gradientColor: const Color(0xFFFFB870),
                      onPressed: onStatistic ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const StatisticScreen(),
                              ),
                            );
                          },
                    ),
                  ),
                  Positioned(
                    top: 535,
                    left: contentLeft,
                    width: contentWidth,
                    child: _HistoryCard(
                      onPressed: onHistory ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                    ),
                  ),
                  Positioned(
                    top: pageHeight - 135,
                    left: (constraints.maxWidth - 80) / 2,
                    child: _ScanButton(
                      // onPressed: onScan ??
                      //     () {
                      //       Navigator.of(context).push(
                      //         MaterialPageRoute<void>(
                      //           builder: (_) => const ScanScreen(),
                      //         ),
                      //      );
                      //    },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/logo.svg', // Sesuaikan dengan path file SVG Anda
          width: 50,               // Sesuaikan ukuran sesuai kebutuhan
          height: 50,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.userName, this.onPressed});

  final String userName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              const SizedBox(width: 15),
              Container(
                width: 43.83,
                height: 43.83,
                decoration: ShapeDecoration(
                  color: const Color(0xFFF8F8F8),
                  shape: OvalBorder(
                    side: BorderSide(
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignCenter,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/profile.svg',
                    width: 32.87,
                    height: 32.87,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hi!',
                      style: TextStyle(
                        color: Color(0xFF1E1E1E),
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Color(0xFFEB5C5C),
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.period, required this.expenses});

  final String period;
  final String expenses;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      decoration: BoxDecoration(
        color: const Color(0xDDF8F8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Period\n',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 14,
                    fontFamily: 'Bricolage Grotesque',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: period,
                  style: const TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontSize: 14,
                    fontFamily: 'Bricolage Grotesque',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFBDBDB),
              border: Border.all(color: const Color(0xFFE42525)),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(
              expenses,
              style: const TextStyle(
                color: Color(0xFFE42525),
                fontFamily: 'Bricolage Grotesque',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.label,
    required this.asset,
    required this.assetWidth,
    required this.assetHeight,
    required this.gradientColor,
    this.onPressed,
  });

  final String label;
  final String asset;
  final double assetWidth;
  final double assetHeight;
  final Color gradientColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 165,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: const Alignment(0.50, -0.00),
              end: const Alignment(0.50, 1.00),
              colors: [const Color(0x00F8F8F8), gradientColor],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              SizedBox(
                width: 90,
                height: 90,
                child: Center(
                  child: SvgPicture.asset(
                    asset,
                    width: assetWidth,
                    height: assetHeight,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 165,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment(0.50, -0.00),
              end: Alignment(0.50, 1.00),
              colors: [Color(0x00F8F8F8), Color(0xFFD2BFEE)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 20),
              SizedBox(
                width: 90,
                height: 90,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/history.svg',
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'History',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F1E1E1E),
            blurRadius: 5,
            offset: Offset(3, 0),
          ),
          BoxShadow(
            color: Color(0x3F1E1E1E),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x3FCCCCCC),
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
          BoxShadow(
            color: Color(0x3FCCCCCC),
            blurRadius: 5,
            offset: Offset(-3, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(100),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/scan.svg',
              width: 35,
              height: 35,
            ),
          ),
        ),
      ),
    );
  }
}