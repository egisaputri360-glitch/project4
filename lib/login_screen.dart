import 'package:flutter/material.dart';
import 'home_screen.dart' show CrudScreen;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // background
            foregroundColor: Colors.white, // warna teks dan ikon
          ),
          icon: const Icon(Icons.list),
          label: const Text('Lihat Data Siswa'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrudScreen(), // tanpa "const"
              ),
            );
          },
        ),
      ),
    );
  }
}
