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

  List<String> dusunList = [];

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

    // 1️⃣ Mapping data siswa
    if (widget.data != null) {
      nisnController.text = widget.data!['nisn']?.toString() ?? '';
      namaController.text = widget.data!['nama_panjang']?.toString() ?? '';
      jkController.text = widget.data!['jenis_kelamin']?.toString() ?? '';
      selectedJenisKelamin = jkController.text.isNotEmpty ? jkController.text : null;
      agamaController.text = widget.data!['agama']?.toString() ?? '';

      // Tanggal lahir: cek apakah data ada, ubah ke format string yyyy-mm-dd
      final ttl = widget.data!['tempat_lahir'];
      if (ttl != null && ttl is String && ttl.isNotEmpty) {
        ttlController.text = ttl;
      } else if (ttl != null && ttl is DateTime) {
        ttlController.text =
            "${ttl.year}-${ttl.month.toString().padLeft(2, '0')}-${ttl.day.toString().padLeft(2, '0')}";
      } else {
        ttlController.text = '';
      }

      nomorHpController.text = widget.data!['nomor_hp']?.toString() ?? '';
      nikController.text = widget.data!['nik']?.toString() ?? '';
      alamatController.text = widget.data!['alamat']?.toString() ?? '';

      // 2️⃣ Mapping data wilayah
      final wilayah = widget.data!['wilayah'] ?? {};
      dusunController.text = wilayah['dusun']?.toString() ?? '';
      desaController.text = wilayah['desa']?.toString() ?? '';
      kecamatanController.text = wilayah['kecamatan']?.toString() ?? '';
      kabupatenController.text = wilayah['kabupaten']?.toString() ?? '';
      provinsiController.text = wilayah['provinsi']?.toString() ?? '';
      kodePosController.text = wilayah['kode_pos']?.toString() ?? '';

      // 3️⃣ Mapping data ortu
      final ortu = widget.data!['ortu'] ?? {};
      ayahController.text = ortu['nama_ayah']?.toString() ?? '';
      ibuController.text = ortu['nama_ibu']?.toString() ?? '';
      waliController.text = ortu['nama_wali']?.toString() ?? '';
      alamatWaliController.text = ortu['alamat_wali']?.toString() ?? '';
    }

    // 4️⃣ Fetch list dusun dari database untuk Autocomplete
    _fetchDusunList();
  }

  Future<void> _fetchDusunList() async {
    try {
      final response = await client.from('wilayah').select('dusun');
      // Pastikan response berupa List<Map<String, dynamic>>
      dusunList = (response as List).map((e) => e['dusun'].toString()).toList();
      if (mounted) setState(() {});
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Gagal fetch dusun: ${e.message}")),
        );
      }
    }
  }

  // 2️⃣ Ambil data wilayah otomatis berdasarkan dusun yang dipilih
  Future<void> _fetchWilayahFromDusun(String dusun) async {
    try {
      final res = await client.from('wilayah').select('*').eq('dusun', dusun);

      if ((res as List).isNotEmpty) {
        final wilayah = res.first; // ambil baris pertama
        if (mounted) {
          setState(() {
            desaController.text = wilayah['desa'] ?? '';
            kecamatanController.text = wilayah['kecamatan'] ?? '';
            kabupatenController.text = wilayah['kabupaten'] ?? '';
            provinsiController.text = wilayah['provinsi'] ?? '';
            kodePosController.text = wilayah['kode_pos'] ?? '';
          });
        }
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal ambil wilayah: ${e.message}")),
        );
      }
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? wilayahId = widget.data?['wilayah_id']?.toString();
      String? siswaId = widget.data?['id']?.toString();

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
        wilayahId = (res as List).first['id'].toString();
      } else {
        // jika wilayahId null, mungkin data awal belum punya wilayah, jadi insert
        if (wilayahId == null || wilayahId.isEmpty) {
          final res = await client.from('wilayah').insert(wilayahData).select();
          wilayahId = (res as List).first['id'].toString();
        } else {
          await client.from('wilayah').update(wilayahData).eq('id', wilayahId as Object);
        }
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
        siswaId = (res as List).first['id'].toString();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Gagal simpan: ${e.message}")),
        );
      }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("=== Data Siswa ===", style: TextStyle(fontWeight: FontWeight.bold)),
              _field("NISN", nisnController),
              _field("Nama Panjang", namaController),

              // Dropdown Jenis Kelamin
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: selectedJenisKelamin,
                  items: const [
                    DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedJenisKelamin = value;
                      jkController.text = value ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Jenis Kelamin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue[50],
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Pilih jenis kelamin' : null,
                ),
              ),

              _field("Agama", agamaController),

              const SizedBox(height: 12),

              // Tanggal lahir dengan DatePicker
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextFormField(
                  controller: ttlController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Tanggal Lahir",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.blue[50],
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: ttlController.text.isNotEmpty
                          ? DateTime.tryParse(ttlController.text) ?? DateTime.now()
                          : DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      ttlController.text = date.toIso8601String().split('T').first;
                    }
                  },
                  validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                ),
              ),

              _field("No HP", nomorHpController),
              _field("NIK", nikController),
              _field("Alamat", alamatController),

              const SizedBox(height: 16),
              const Text("=== Data Wilayah ===", style: TextStyle(fontWeight: FontWeight.bold)),

              // Autocomplete Dusun
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') return const Iterable<String>.empty();
                    return dusunList.where((dusun) => dusun.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    controller.text = dusunController.text;
                    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      decoration: InputDecoration(
                        labelText: 'Dusun',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.blue[50],
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                    );
                  },
                  onSelected: (value) async {
                    dusunController.text = value;
                    await _fetchWilayahFromDusun(value);
                  },
                ),
              ),

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
