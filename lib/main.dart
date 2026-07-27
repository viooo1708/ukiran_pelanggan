import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'screens/splash_screen.dart';
import 'providers/notification_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const KriyaUkirApp(),
    ),
  );
}

class KriyaUkirApp extends StatelessWidget {
  const KriyaUkirApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Definisi Palet Warna sesuai Dashboard Web
    const Color primaryBrown = Color(0xFF5D4037);
    const Color darkBrown = Color(0xFF3E2723);
    const Color bgCream = Color(0xFFFDFBF7);
    const Color borderCream = Color(0xFFEADFD8);
    const Color textDark = Color(0xFF1C1917);
    const Color textMuted = Color(0xFF6B7280);

    return MaterialApp(
      title: 'Kriya Ukir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgCream, // Latar belakang aplikasi krem
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBrown,
          primary: primaryBrown,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: textDark,
        ),
        
        // Menyamakan Tipografi dengan Web
        textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
          bodyColor: textDark,
          displayColor: darkBrown,
        ),

        // Styling AppBar (Navigasi Atas)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: darkBrown,
          elevation: 0,
          scrolledUnderElevation: 1, // Sedikit shadow saat di-scroll
          centerTitle: true,
          iconTheme: IconThemeData(color: primaryBrown),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800, // Extra Bold
            color: darkBrown,
            letterSpacing: 0.5,
          ),
        ),

        // Styling Tombol Utama
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBrown,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: primaryBrown.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // rounded-xl
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Styling Form Input Text
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: textMuted, fontSize: 13),
          labelStyle: const TextStyle(
            color: textMuted, 
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 0.5,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderCream),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderCream),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBrown, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),

        // Styling Card (Mirip class="bg-white rounded-2xl border border-[#eadfd8]")
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // rounded-2xl
            side: const BorderSide(color: borderCream, width: 1),
          ),
        ),

        // Styling Divider / Garis Pemisah
        dividerTheme: const DividerThemeData(
          color: borderCream,
          thickness: 1,
          space: 24,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}