import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_form.dart';

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

  Future<void> _fetchData() async {
    setState(() { _loading = true; });
    try {
      final response = await client
          .from('siswa')
          .select(', wilayah(), ortu(*)')
          .order('nama_panjang');

      final data = (response as List<dynamic>).map((json) {
        return {
          'id': json['id'], // Biarkan sebagai dynamic, bisa String atau int
          'nama_panjang': json['nama_panjang'] ?? 'N/A',
          'nisn': json['nisn']?.toString() ?? 'N/A', // Convert to String
          'agama': json['agama']?.toString() ?? 'N/A',
          'jenis_kelamin': json['jenis_kelamin']?.toString() ?? 'N/A',
          'tempat_lahir': json['tempat_lahir']?.toString() ?? 'N/A',
          'nomor_hp': json['nomor_hp']?.toString() ?? 'N/A',
          'nik': json['nik']?.toString() ?? 'N/A',
          'alamat': json['alamat']?.toString() ?? 'N/A',
          'wilayah_id': json['wilayah_id'], // Keep as dynamic
          'wilayah': json['wilayah'],
          'ortu': json['ortu'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          siswaList = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠ Gagal fetch data: $e")),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _deleteData(dynamic siswaId, dynamic wilayahId) async {
    setState(() { _loading = true; });
    try {
      // Delete ortu first (child table)
      await client.from('ortu').delete().eq('siswa_id', siswaId);
      
      // Delete siswa
      await client.from('siswa').delete().eq('id', siswaId);
      
      // Delete wilayah if exists
      if (wilayahId != null) {
        await client.from('wilayah').delete().eq('id', wilayahId);
      }
      
      _fetchData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Data berhasil dihapus")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠ Gagal hapus: $e")),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("📋 Data Siswa"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : siswaList.isEmpty
              ? const Center(child: Text("Belum ada data siswa"))
              : ListView.builder(
                  itemCount: siswaList.length,
                  itemBuilder: (context, index) {
                    final siswa = siswaList[index];
                    final wilayahId = siswa['wilayah']?['id'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          siswa['nama_panjang']?.toString() ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text("NISN: ${siswa['nisn']?.toString() ?? 'N/A'}"),
                            Text("Jenis Kelamin: ${siswa['jenis_kelamin']?.toString() ?? 'N/A'}"),
                            Text("Agama: ${siswa['agama']?.toString() ?? 'N/A'}"),
                            Text("Desa: ${siswa['wilayah']?['desa']?.toString() ?? 'N/A'}"),
                            Text("Nama Ayah: ${siswa['ortu']?['nama_ayah']?.toString() ?? 'N/A'}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentForm(siswaData: siswa), // Fix: gunakan siswaData
                                  ),
                                );
                                if (result == true) _fetchData();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(siswa['id'], wilayahId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentForm()),
          );
          if (created == true) _fetchData();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Add confirmation dialog for delete
  void _showDeleteDialog(dynamic siswaId, dynamic wilayahId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Apakah Anda yakin ingin menghapus data ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteData(siswaId, wilayahId);
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}