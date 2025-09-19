import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'crud_screen.dart'; // Import StudentForm for add/edit

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Tidak ada koneksi internet!")),
      );
    }
    return;
  }

  try {
    final response = await client
        .from('siswa')
        .select('''
          id, nisn, nama_panjang, jenis_kelamin, agama, tempat_lahir, nomor_hp, nik, alamat,
          wilayah (dusun, desa, kecamatan, kabupaten, provinsi, kode_pos),
          ortu (nama_ayah, nama_ibu, nama_wali, alamat_wali)
        ''')
        .order('nisn');

    print(response); // 🔎 debug

    setState(() {
      siswaList = List<Map<String, dynamic>>.from(response);
      _loading = false;
    });
  } on PostgrestException catch (e) {
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Masalah database: ${e.message}")),
      );
    }
  }
}


  Future<void> _deleteData(String id) async {
    if (!await _checkInternet()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Tidak ada koneksi internet!")),
        );
      }
      return;
    }
    try {
      // Delete related ortu and wilayah records first
      await client.from('ortu').delete().eq('siswa_id', id);
      await client.from('wilayah').delete().eq('id', (await client.from('siswa').select('wilayah_id').eq('id', id)).first['wilayah_id']);
      await client.from('siswa').delete().eq('id', id);
      _fetchData();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Gagal hapus: ${e.message}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Match student_form.dart background
      appBar: AppBar(
        title: const Text("📋 Data Siswa"),
        backgroundColor: Colors.blueAccent, // Consistent with other screens
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : siswaList.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada data siswa",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                )
              : ListView.builder(
                  itemCount: siswaList.length,
                  itemBuilder: (context, index) {
                    final siswa = siswaList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Consistent rounded corners
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          siswa['nama_panjang'] ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("NISN: ${siswa['nisn'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                            Text("Jenis Kelamin: ${siswa['jenis_kelamin'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                            Text("Agama: ${siswa['agama'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                            Text("Tempat Lahir: ${siswa['tempat_lahir'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                            Text("Alamat: ${siswa['alamat'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                            Text("Desa: ${siswa['wilayah']?['desa'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                            Text("Nama Ayah: ${siswa['ortu']?['nama_ayah'] ?? 'N/A'}", style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentForm(data: siswa), // Use StudentForm for edit
                                  ),
                                );
                                if (updated == true) _fetchData();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteData(siswa['id'].toString()),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Optional: Show detailed view on tap
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text(siswa['nama_panjang'] ?? 'N/A'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("NISN: ${siswa['nisn'] ?? 'N/A'}"),
                                    Text("Jenis Kelamin: ${siswa['jenis_kelamin'] ?? 'N/A'}"),
                                    Text("Agama: ${siswa['agama'] ?? 'N/A'}"),
                                    Text("Tempat Lahir: ${siswa['tempat_lahir'] ?? 'N/A'}"),
                                    Text("No HP: ${siswa['nomor_hp'] ?? 'N/A'}"),
                                    Text("NIK: ${siswa['nik'] ?? 'N/A'}"),
                                    Text("Alamat: ${siswa['alamat'] ?? 'N/A'}"),
                                    const Divider(),
                                    Text("Wilayah:", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("Dusun: ${siswa['wilayah']?['dusun'] ?? 'N/A'}"),
                                    Text("Desa: ${siswa['wilayah']?['desa'] ?? 'N/A'}"),
                                    Text("Kecamatan: ${siswa['wilayah']?['kecamatan'] ?? 'N/A'}"),
                                    Text("Kabupaten: ${siswa['wilayah']?['kabupaten'] ?? 'N/A'}"),
                                    Text("Provinsi: ${siswa['wilayah']?['provinsi'] ?? 'N/A'}"),
                                    Text("Kode Pos: ${siswa['wilayah']?['kode_pos'] ?? 'N/A'}"),
                                    const Divider(),
                                    Text("Orang Tua/Wali:", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("Nama Ayah: ${siswa['ortu']?['nama_ayah'] ?? 'N/A'}"),
                                    Text("Nama Ibu: ${siswa['ortu']?['nama_ibu'] ?? 'N/A'}"),
                                    Text("Nama Wali: ${siswa['ortu']?['nama_wali'] ?? 'N/A'}"),
                                    Text("Alamat Wali: ${siswa['ortu']?['alamat_wali'] ?? 'N/A'}"),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Tutup"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentForm()), // Use StudentForm for add
          );
          if (created == true) _fetchData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}