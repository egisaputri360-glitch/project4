import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      await client.from('ortu').delete().eq('siswa_id', id);
      await client
          .from('wilayah')
          .delete()
          .eq('id',
              (await client.from('siswa').select('wilayah_id').eq('id', id))
                  .first['wilayah_id']);
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
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("📋 Data Siswa"),
        backgroundColor: Colors.blueAccent,
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
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                            Text("NISN: ${siswa['nisn'] ?? 'N/A'}"),
                            Text("Jenis Kelamin: ${siswa['jenis_kelamin'] ?? 'N/A'}"),
                            Text("Agama: ${siswa['agama'] ?? 'N/A'}"),
                            Text("Tempat Tanggal Lahir: ${siswa['tempat_lahir'] ?? 'N/A'}"),
                            Text("Alamat: ${siswa['alamat'] ?? 'N/A'}"),
                            Text("Desa: ${siswa['wilayah']?['desa'] ?? 'N/A'}"),
                            Text("Nama Ayah: ${siswa['ortu']?['nama_ayah'] ?? 'N/A'}"),
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
                                    builder: (_) =>
                                        StudentForm(data: siswa), // form edit
                                  ),
                                );
                                if (updated == true) _fetchData();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteData(siswa['id'].toString()),
                            ),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: Text(siswa['nama_panjang'] ?? 'N/A'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("NISN: ${siswa['nisn'] ?? 'N/A'}"),
                                    Text("Jenis Kelamin: ${siswa['jenis_kelamin'] ?? 'N/A'}"),
                                    Text("Agama: ${siswa['agama'] ?? 'N/A'}"),
                                    Text("Tempat Tanggal Lahir: ${siswa['tempat_lahir'] ?? 'N/A'}"),
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
                                    Text("Orang Tua / Wali:", style: const TextStyle(fontWeight: FontWeight.bold)),
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
            MaterialPageRoute(builder: (_) => const StudentForm()), // form tambah
          );
          if (created == true) _fetchData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ======================= FORM TAMBAH/EDIT =======================

class StudentForm extends StatefulWidget {
  final Map<String, dynamic>? data;
  const StudentForm({super.key, this.data});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final client = Supabase.instance.client;

  final nisnController = TextEditingController();
  final namaController = TextEditingController();
  final agamaController = TextEditingController();
  final tempatLahirController = TextEditingController();
  final nomorHpController = TextEditingController();
  final nikController = TextEditingController();
  final alamatController = TextEditingController();
  final dusunController = TextEditingController();
  final desaController = TextEditingController();
  final kecamatanController = TextEditingController();
  final kabupatenController = TextEditingController();
  final provinsiController = TextEditingController();
  final kodePosController = TextEditingController();
  final ayahController = TextEditingController();
  final ibuController = TextEditingController();
  final waliController = TextEditingController();
  final alamatWaliController = TextEditingController();

  String? selectedJenisKelamin;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      nisnController.text = widget.data!['nisn'] ?? '';
      namaController.text = widget.data!['nama_panjang'] ?? '';
      selectedJenisKelamin = widget.data!['jenis_kelamin'];
      agamaController.text = widget.data!['agama'] ?? '';
      tempatLahirController.text = widget.data!['tempat_lahir'] ?? '';
      nomorHpController.text = widget.data!['nomor_hp'] ?? '';
      nikController.text = widget.data!['nik'] ?? '';
      alamatController.text = widget.data!['alamat'] ?? '';
      dusunController.text = widget.data!['wilayah']?['dusun'] ?? '';
      desaController.text = widget.data!['wilayah']?['desa'] ?? '';
      kecamatanController.text = widget.data!['wilayah']?['kecamatan'] ?? '';
      kabupatenController.text = widget.data!['wilayah']?['kabupaten'] ?? '';
      provinsiController.text = widget.data!['wilayah']?['provinsi'] ?? '';
      kodePosController.text = widget.data!['wilayah']?['kode_pos'] ?? '';
      ayahController.text = widget.data!['ortu']?['nama_ayah'] ?? '';
      ibuController.text = widget.data!['ortu']?['nama_ibu'] ?? '';
      waliController.text = widget.data!['ortu']?['nama_wali'] ?? '';
      alamatWaliController.text = widget.data!['ortu']?['alamat_wali'] ?? '';
    }
  }

  Future<void> _saveData() async {
    if (selectedJenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih jenis kelamin dulu")),
      );
      return;
    }

    final siswaData = {
      'nisn': nisnController.text,
      'nama_panjang': namaController.text,
      'jenis_kelamin': selectedJenisKelamin,
      'agama': agamaController.text,
      'tempat_lahir': tempatLahirController.text,
      'nomor_hp': nomorHpController.text,
      'nik': nikController.text,
      'alamat': alamatController.text,
    };

    try {
      if (widget.data == null) {
        await client.from('siswa').insert(siswaData);
      } else {
        await client
            .from('siswa')
            .update(siswaData)
            .eq('id', widget.data!['id']);
      }

      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Gagal simpan: ${e.message}")),
      );
    }
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data == null ? "Tambah Siswa" : "Edit Siswa"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field("NISN", nisnController),
            _field("Nama Lengkap", namaController),
            DropdownButtonFormField<String>(
              value: selectedJenisKelamin,
              decoration: const InputDecoration(
                labelText: "Jenis Kelamin",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Laki-laki", child: Text("Laki-laki")),
                DropdownMenuItem(value: "Perempuan", child: Text("Perempuan")),
              ],
              onChanged: (value) {
                setState(() => selectedJenisKelamin = value);
              },
            ),
            const SizedBox(height: 12),
            _field("Agama", agamaController),
            _field("Tempat Tanggal Lahir", tempatLahirController),
            _field("Nomor HP", nomorHpController),
            _field("NIK", nikController),
            _field("Alamat", alamatController),
            const Divider(),
            const Text("Data Wilayah", style: TextStyle(fontWeight: FontWeight.bold)),
            _field("Dusun", dusunController),
            _field("Desa", desaController),
            _field("Kecamatan", kecamatanController),
            _field("Kabupaten", kabupatenController),
            _field("Provinsi", provinsiController),
            _field("Kode Pos", kodePosController),
            const Divider(),
            const Text("Orang Tua / Wali", style: TextStyle(fontWeight: FontWeight.bold)),
            _field("Nama Ayah", ayahController),
            _field("Nama Ibu", ibuController),
            _field("Nama Wali", waliController),
            _field("Alamat Wali", alamatWaliController),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save),
              label: const Text("Simpan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
