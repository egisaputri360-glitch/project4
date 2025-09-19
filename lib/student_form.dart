import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentCrudScreen extends StatefulWidget {
  const StudentCrudScreen({super.key});

  @override
  State<StudentCrudScreen> createState() => _StudentCrudScreenState();
}

class _StudentCrudScreenState extends State<StudentCrudScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await supabase
          .from('siswa')
          .select('id, nisn, nama_panjang, jenis_kelamin, agama, tempat_lahir, nomor_hp, nik, alamat')
          .order('nisn');
      setState(() => students = response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil data: $e")),
      );
    }
  }

  Future<void> _addOrEditStudent({Map<String, dynamic>? student}) async {
    final nisnController = TextEditingController(text: student?['nisn']);
    final namaController = TextEditingController(text: student?['nama_panjang']);
    final jkController = TextEditingController(text: student?['jenis_kelamin']);
    final agamaController = TextEditingController(text: student?['agama']);
    final ttlController = TextEditingController(text: student?['tempat_lahir']);
    final hpController = TextEditingController(text: student?['nomor_hp']);
    final nikController = TextEditingController(text: student?['nik']);
    final alamatController = TextEditingController(text: student?['alamat']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(student == null ? "Tambah Data Siswa" : "Edit Data Siswa"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField("NISN", nisnController),
                _buildTextField("Nama Lengkap", namaController),
                _buildTextField("Jenis Kelamin", jkController),
                _buildTextField("Agama", agamaController),
                _buildTextField("Tempat Lahir", ttlController),
                _buildTextField("No HP", hpController),
                _buildTextField("NIK", nikController),
                _buildTextField("Alamat", alamatController),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Simpan"),
              onPressed: () async {
                final data = {
                  'nisn': nisnController.text,
                  'nama_panjang': namaController.text,
                  'jenis_kelamin': jkController.text,
                  'agama': agamaController.text,
                  'tempat_lahir': ttlController.text,
                  'nomor_hp': hpController.text,
                  'nik': nikController.text,
                  'alamat': alamatController.text,
                };

                try {
                  if (student == null) {
                    await supabase.from('siswa').insert(data);
                  } else {
                    await supabase.from('siswa').update(data).eq('id', student['id']);
                  }
                  Navigator.pop(context);
                  _fetchStudents();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal menyimpan data: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStudent(String id) async {
    try {
      await supabase.from('siswa').delete().eq('id', id);
      _fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghapus data: $e")),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.blue[50],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Data Siswa"),
        backgroundColor: Colors.blueAccent,
      ),
      body: students.isEmpty
          ? const Center(child: Text("Belum ada data"))
          : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(student['nama_panjang']),
                    subtitle: Text("NISN: ${student['nisn']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _addOrEditStudent(student: student),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteStudent(student['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditStudent(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
