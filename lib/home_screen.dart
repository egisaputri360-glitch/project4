import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project4/crud_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrudScreen extends StatefulWidget {
  const CrudScreen({super.key}); // <- harus sama persis

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  final client = Supabase.instance.client;
  List<Map<String, dynamic>> siswaList = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    if (!await _checkInternet()) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Tidak ada koneksi internet!")),
      );
      return;
    }

    try {
      final response = await client.from('students').select().order('id');
      setState(() {
        siswaList = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } on PostgrestException catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Masalah database: ${e.message}")),
      );
    }
  }

  Future<void> _deleteData(int id) async {
    if (!await _checkInternet()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Tidak ada koneksi internet!")),
      );
      return;
    }
    try {
      await client.from('students').delete().eq('id', id);
      _fetchData();
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Gagal hapus: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Siswa")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: siswaList.length,
              itemBuilder: (context, index) {
                final siswa = siswaList[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(siswa['nama_lengkap'] ?? ''),
                    subtitle: Text("NISN: ${siswa['nisn'] ?? ''}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentForm(data: siswa),
                              ),
                            );
                            if (updated == true) _fetchData();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteData(siswa['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentForm()),
          );
          if (created == true) _fetchData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}