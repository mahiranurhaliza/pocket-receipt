import 'package:flutter/material.dart';

// Mengimpor seluruh screen/halaman yang telah dirancang
import 'welcome.dart';   // Layar awal/welcome
// import 'login.dart';     // Layar login[cite: 23]
// import 'signup.dart';    // Layar registrasi/signup[cite: 25]
// import 'home.dart';      // Layar utama/dashboard[cite: 22]
// import 'portfolio.dart'; // Layar portfolio[cite: 24]
// import 'statistic.dart'; // Layar statistik[cite: 26]
// import 'history.dart';   // Layar riwayat transaksi[cite: 20]

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker App',
      theme: ThemeData(
        fontFamily: 'Bricolage Grotesque', // Standar font utama aplikasi
      ),
      // Menjadikan WelcomeScreen sebagai halaman pertama saat aplikasi dibuka
      home: const WelcomeScreen(),
    );
  }
}