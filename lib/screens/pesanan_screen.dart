import 'package:flutter/material.dart';

class PesananScreen extends StatelessWidget {
  const PesananScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: const Center(child: Text('Daftar pesanan Anda akan muncul di sini')),
    );
  }
}