import 'package:flutter/material.dart';
// no provider needed here

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Notifikasi'),
            value: true,
            onChanged: (_) {},
          ),
          ListTile(
            title: Text('Ubah Profil'),
            onTap: () {},
          ),
          ListTile(
            title: Text('Ubah Kata Sandi'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
