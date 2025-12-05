import 'package:flutter/material.dart';

// SalesStatisticsScreen removed - placeholder to avoid breaking imports.
class SalesStatisticsScreen extends StatelessWidget {
  const SalesStatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik Penjualan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Fitur Statistik Penjualan telah dihapus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
