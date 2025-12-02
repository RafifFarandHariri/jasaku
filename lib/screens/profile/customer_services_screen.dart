import 'package:flutter/material.dart';

class CustomerServicesScreen extends StatelessWidget {
  const CustomerServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customer Services')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(title: Text('Hubungi Kami'), subtitle: Text('support@jasaku.local')),
            SizedBox(height: 12),
            ListTile(title: Text('FAQ'), onTap: () {}),
            ListTile(title: Text('Lapor Masalah'), onTap: () {}),
          ],
        ),
      ),
    );
  }
}
