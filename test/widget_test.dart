import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Sesuaikan path import jika diperlukan
import 'package:ukiran_pelanggan/main.dart'; 
import 'package:ukiran_pelanggan/providers/auth_provider.dart';

void main() {
  testWidgets('App starts with Splash Screen smoke test', (WidgetTester tester) async {
    // Karena aplikasi kita menggunakan Provider, kita harus membungkusnya 
    // dengan MultiProvider sama seperti di file main.dart asli.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const KriyaUkirApp(),
      ),
    );

    // Memastikan bahwa saat aplikasi pertama kali dijalankan,
    // teks 'KRIYA UKIR' dari SplashScreen muncul di layar.
    expect(find.text('KRIYA UKIR'), findsOneWidget);

    // Memastikan bahwa ikon palu (handyman) juga ada di layar.
    expect(find.byIcon(Icons.handyman), findsOneWidget);
  });
}