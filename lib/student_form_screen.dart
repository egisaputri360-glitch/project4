import 'package:flutter/material.dart';

class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({super.key});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final nisnController = TextEditingController();
  final namaController = TextEditingController();
  final jkController = TextEditingController();
  final agamaController = TextEditingController();
  final ttlController = TextEditingController();
  final telpController = TextEditingController();
  final nikController = TextEditingController();
  final jalanController = TextEditingController();
  final rtrwController = TextEditingController();
  final dusunController = TextEditingController();
  final desaController = TextEditingController();
  final kecamatanController = TextEditingController();
  final kabupatenController = TextEditingController();
  final provinsiController = TextEditingController();
  final kodeposController = TextEditingController();
  final ayahController = TextEditingController();
  final ibuController = TextEditingController();
  final waliController = TextEditingController();
  final alamatOrtuController = TextEditingController();

  @override
  void dispose() {
    nisnController.dispose();
    namaController.dispose();
    jkController.dispose();
    agamaController.dispose();
    ttlController.dispose();
    telpController.dispose();
    nikController.dispose();
    jalanController.dispose();
    rtrwController.dispose();
    dusunController.dispose();
    desaController.dispose();
    kecamatanController.dispose();
    kabupatenController.dispose();
    provinsiController.dispose();
    kodeposController.dispose();
    ayahController.dispose();
    ibuController.dispose();
    waliController.dispose();
    alamatOrtuController.dispose();
    super.dispose();
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data berhasil disimpan!")),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.isEmpty ? '$label wajib diisi' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Data Siswa")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("NISN", nisnController),
              _buildTextField("Nama Lengkap", namaController),
              _buildTextField("Jenis Kelamin", jkController),
              _buildTextField("Agama", agamaController),
              _buildTextField("Tempat & Tanggal Lahir", ttlController),
              _buildTextField("No Telp/HP", telpController),
              _buildTextField("NIK", nikController),
              const SizedBox(height: 10),
              const Text("Alamat", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildTextField("Jalan", jalanController),
              _buildTextField("RT/RW", rtrwController),
              _buildTextField("Dusun", dusunController),
              _buildTextField("Desa", desaController),
              _buildTextField("Kecamatan", kecamatanController),
              _buildTextField("Kabupaten", kabupatenController),
              _buildTextField("Provinsi", provinsiController),
              _buildTextField("Kode Pos", kodeposController),
              const SizedBox(height: 10),
              const Text("Orang Tua / Wali", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildTextField("Nama Ayah", ayahController),
              _buildTextField("Nama Ibu", ibuController),
              _buildTextField("Nama Wali", waliController),
              _buildTextField("Alamat Orang Tua/Wali", alamatOrtuController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
