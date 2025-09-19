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
    setState(() => _loading = true);
    try {
      final response = await client
          .from('siswa')
          .select(', wilayah(), ortu(*)')
          .order('nama_panjang');

      final data = (response as List<dynamic>).map((json) {
        return {
          'id': json['id'],
          'nama_panjang': json['nama_panjang'] ?? 'N/A',
          'nisn': json['nisn']?.toString() ?? 'N/A',
          'agama': json['agama']?.toString() ?? 'N/A',
          'jenis_kelamin': json['jenis_kelamin']?.toString() ?? 'N/A',
          'tempat_lahir': json['tempat_lahir']?.toString() ?? 'N/A',
          'nomor_hp': json['nomor_hp']?.toString() ?? 'N/A',
          'nik': json['nik']?.toString() ?? 'N/A',
          'alamat': json['alamat']?.toString() ?? 'N/A',
          'wilayah_id': json['wilayah_id'],
          'wilayah': json['wilayah'],
          'ortu': json['ortu'],
        };
      }).toList();

      if (mounted) {
        setState(() => siswaList = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠ Gagal fetch data: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteData(dynamic siswaId, dynamic wilayahId) async {
    setState(() => _loading = true);
    try {
      await client.from('ortu').delete().eq('siswa_id', siswaId);
      await client.from('siswa').delete().eq('id', siswaId);
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
      if (mounted) setState(() => _loading = false);
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
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : siswaList.isEmpty
              ? const Center(
                  child: Text("Belum ada data siswa",
                      style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: siswaList.length,
                  itemBuilder: (context, index) {
                    final siswa = siswaList[index];
                    final wilayahId = siswa['wilayah']?['id'];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent.shade100,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            siswa['nama_panjang'] ?? 'N/A',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text("📌 NISN: ${siswa['nisn']}"),
                              Text("👤 Jenis Kelamin: ${siswa['jenis_kelamin']}"),
                              Text("🕌 Agama: ${siswa['agama']}"),
                              Text("🏡 Desa: ${siswa['wilayah']?['desa'] ?? 'N/A'}"),
                              Text("👨 Ayah: ${siswa['ortu']?['nama_ayah'] ?? 'N/A'}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          StudentForm(siswaData: siswa),
                                    ),
                                  );
                                  if (result == true) _fetchData();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteDialog(siswa['id'], wilayahId),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Siswa",
            style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentForm()),
          );
          if (created == true) _fetchData();
        },
      ),
    );
  }

  void _showDeleteDialog(dynamic siswaId, dynamic wilayahId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Apakah Anda yakin ingin menghapus data ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteData(siswaId, wilayahId);
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }
}
