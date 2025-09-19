import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentForm extends StatefulWidget {
  final Map<String, dynamic>? data; // Untuk edit
  const StudentForm({super.key, this.data});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  String? selectedJenisKelamin;





  // === DATA SISWA ===
  final nisnController = TextEditingController();
  final namaController = TextEditingController();
  final jkController = TextEditingController();
  final agamaController = TextEditingController();
  final ttlController = TextEditingController();
  final nomorHpController = TextEditingController();
  final nikController = TextEditingController();
  final alamatController = TextEditingController();

  // === DATA WILAYAH ===
  final dusunController = TextEditingController();
  final desaController = TextEditingController();
  final kecamatanController = TextEditingController();
  final kabupatenController = TextEditingController();
  final provinsiController = TextEditingController();
  final kodePosController = TextEditingController();

  // === DATA ORTU ===
  final ayahController = TextEditingController();
  final ibuController = TextEditingController();
  final waliController = TextEditingController();
  final alamatWaliController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      // Mapping data siswa
      nisnController.text = widget.data!['nisn'] ?? '';
      namaController.text = widget.data!['nama_panjang'] ?? '';
      jkController.text = widget.data!['jenis_kelamin'] ?? '';
      agamaController.text = widget.data!['agama'] ?? '';
      ttlController.text = widget.data!['tempat_lahir'] ?? '';
      nomorHpController.text = widget.data!['nomor_hp'] ?? '';
      nikController.text = widget.data!['nik'] ?? '';
      alamatController.text = widget.data!['alamat'] ?? '';

      // Mapping data wilayah
      final wilayah = widget.data!['wilayah'] ?? {};
      dusunController.text = wilayah['dusun'] ?? '';
      desaController.text = wilayah['desa'] ?? '';
      kecamatanController.text = wilayah['kecamatan'] ?? '';
      kabupatenController.text = wilayah['kabupaten'] ?? '';
      provinsiController.text = wilayah['provinsi'] ?? '';
      kodePosController.text = wilayah['kode_pos'] ?? '';

      // Mapping data ortu
      final ortu = widget.data!['ortu'] ?? {};
      ayahController.text = ortu['nama_ayah'] ?? '';
      ibuController.text = ortu['nama_ibu'] ?? '';
      waliController.text = ortu['nama_wali'] ?? '';
      alamatWaliController.text = ortu['alamat_wali'] ?? '';
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? wilayahId = widget.data?['wilayah_id'];
      String? siswaId = widget.data?['id'];

      // 1️⃣ Insert/update wilayah
      final wilayahData = {
        'dusun': dusunController.text,
        'desa': desaController.text,
        'kecamatan': kecamatanController.text,
        'kabupaten': kabupatenController.text,
        'provinsi': provinsiController.text,
        'kode_pos': kodePosController.text,
      };
      if (widget.data == null) {
        final res = await client.from('wilayah').insert(wilayahData).select();
        wilayahId = (res as List).first['id'];
      } else {
        await client.from('wilayah').update(wilayahData).eq('id', wilayahId as Object);
      }

      // 2️⃣ Insert/update siswa
      final siswaData = {
        'nisn': nisnController.text,
        'nama_panjang': namaController.text,
        'jenis_kelamin': jkController.text,
        'agama': agamaController.text,
        'tempat_lahir': ttlController.text,
        'nomor_hp': nomorHpController.text,
        'nik': nikController.text,
        'alamat': alamatController.text,
        'wilayah_id': wilayahId,
      };
      if (widget.data == null) {
        final res = await client.from('siswa').insert(siswaData).select();
        siswaId = (res as List).first['id'];
      } else {
        await client.from('siswa').update(siswaData).eq('id', siswaId as Object);
      }

      // 3️⃣ Insert/update ortu
      final ortuData = {
        'nama_ayah': ayahController.text,
        'nama_ibu': ibuController.text,
        'nama_wali': waliController.text,
        'alamat_wali': alamatWaliController.text,
        'siswa_id': siswaId,
      };
      if (widget.data == null) {
        await client.from('ortu').insert(ortuData);
      } else {
        final ortuList = await client.from('ortu').select('*').eq('siswa_id', siswaId as Object);
        if ((ortuList as List).isEmpty) {
          await client.from('ortu').insert(ortuData);
        } else {
          await client.from('ortu').update(ortuData).eq('siswa_id', siswaId as Object);
        }
      }

      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Gagal simpan: ${e.message}")),
      );
    }
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.blue[50],
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
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
    body: Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("=== Data Siswa ===", style: TextStyle(fontWeight: FontWeight.bold)),
            _field("NISN", nisnController),
            _field("Nama Panjang", namaController),

            // 🔥 Dropdown Jenis Kelamin
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: DropdownButtonFormField<String>(
                value: selectedJenisKelamin,
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedJenisKelamin = value;
                    jkController.text = value ?? ''; // Simpan ke controller
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Jenis Kelamin',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.blue[50],
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Pilih jenis kelamin' : null,
              ),
            ),

            _field("Agama", agamaController),
            _field("Tempat Lahir", ttlController),
            _field("No HP", nomorHpController),
            _field("NIK", nikController),
            _field("Alamat", alamatController),

            const SizedBox(height: 16),
            const Text("=== Data Wilayah ===", style: TextStyle(fontWeight: FontWeight.bold)),
            _field("Dusun", dusunController),
            _field("Desa", desaController),
            _field("Kecamatan", kecamatanController),
            _field("Kabupaten", kabupatenController),
            _field("Provinsi", provinsiController),
            _field("Kode Pos", kodePosController),

            const SizedBox(height: 16),
            const Text("=== Data Orang Tua/Wali ===", style: TextStyle(fontWeight: FontWeight.bold)),
            _field("Nama Ayah", ayahController),
            _field("Nama Ibu", ibuController),
            _field("Nama Wali", waliController),
            _field("Alamat Wali", alamatWaliController),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    ),
  );
}
}