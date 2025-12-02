import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _ctl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_ctl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tulis feedback minimal 10 karakter')));
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terima kasih atas feedback Anda')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ctl,
              maxLines: 6,
              decoration: InputDecoration(hintText: 'Tulis masukan atau laporkan bug...'),
            ),
            SizedBox(height: 12),
            _sending ? CircularProgressIndicator() : ElevatedButton(onPressed: _send, child: Text('Kirim'))
          ],
        ),
      ),
    );
  }
}
