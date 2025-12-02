import 'package:flutter/material.dart';
import 'package:jasaku_app/screens/profile/create_ad_screen.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/auth_provider.dart';

class AdsServicesScreen extends StatelessWidget {
  const AdsServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ads Services')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Iklan dan promosi untuk penyedia jasa akan tersedia di sini.'),
            SizedBox(height: 12),
            ElevatedButton(onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (!(auth.user?.isProvider ?? false)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Anda harus menjadi penyedia jasa terlebih dahulu'), backgroundColor: Colors.orange));
                return;
              }
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAdScreen()));
              if (result == true) {
                // optionally refresh list or show success
              }
            }, child: Text('Pasang Iklan')),
          ],
        ),
      ),
    );
  }
}
