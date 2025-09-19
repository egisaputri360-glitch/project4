import 'package:flutter/material.dart';

class SiswaForm extends StatefulWidget {
  final Map<String, String>? siswa;
  final Function(Map<String, String>) onSave;

  const SiswaForm({super.key, this.siswa, required this.onSave});

  @override
  State<SiswaForm> createState() => _SiswaFormState();
}

class _SiswaFormState extends State<SiswaForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _data = {};

  @override
  void initState() {
    super.initState();
    if (widget.siswa != null) {
      _data.addAll(widget.siswa!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                widget.siswa == null ? "Tambah Data Siswa" : "Edit Data Siswa",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildField("nisn", "NISN"),
              _buildField("nama", "Nama Lengkap"),
              _buildField("jk", "Jenis Kelamin"),
              _buildField("agama", "Agama"),
              _buildField("ttl", "Tempat, Tanggal Lahir"),
              _buildField("telp", "No. Telp/HP"),
              _buildField("nik", "NIK"),
              _buildField("jalan", "Jalan"),
              _buildField("rtrw", "RT/RW"),
              _buildField("dusun", "Dusun"),
              _buildField("desa", "Desa"),
              _buildField("kecamatan", "Kecamatan"),
              _buildField("kabupaten", "Kabupaten"),
              _buildField("provinsi", "Provinsi"),
              _buildField("kodepos", "Kode Pos"),
              _buildField("ayah", "Nama Ayah"),
              _buildField("ibu", "Nama Ibu"),
              _buildField("wali", "Nama Wali"),
              _buildField("alamat_wali", "Alamat Wali"),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.onSave(_data);
                  }
                },
                child: Text(widget.siswa == null ? "Tambah" : "Update"),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: _data[key],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.blue[50],
        ),
        onSaved: (value) => _data[key] = value ?? "",
      ),
    );
  }
}
