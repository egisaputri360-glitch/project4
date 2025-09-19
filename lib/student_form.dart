import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentForm extends StatefulWidget {
  final Map<String, dynamic>? siswaData; // Fix: ganti dari 'data' ke 'siswaData'
  const StudentForm({super.key, this.siswaData});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  String? selectedJenisKelamin;
  List<String> dusunList = [];
  bool _loading = false;

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
    if (widget.siswaData != null) {
      nisnController.text = widget.siswaData!['nisn']?.toString() ?? '';
      namaController.text = widget.siswaData!['nama_panjang']?.toString() ?? '';
      
      // Set jenis kelamin
      final jk = widget.siswaData!['jenis_kelamin']?.toString();
      jkController.text = jk ?? '';
      selectedJenisKelamin = jk;
      
      agamaController.text = widget.siswaData!['agama']?.toString() ?? '';

      // Tanggal lahir: cek apakah data ada, ubah ke format string yyyy-mm-dd
      final ttl = widget.siswaData!['tempat_lahir'];
      if (ttl != null && ttl.toString().isNotEmpty) {
        if (ttl is DateTime) {
          ttlController.text = "${ttl.year}-${ttl.month.toString().padLeft(2,'0')}-${ttl.day.toString().padLeft(2,'0')}";
        } else {
          // Jika sudah string format tanggal
          final dateStr = ttl.toString();
          if (dateStr.contains('-') && dateStr.length >= 10) {
            ttlController.text = dateStr.substring(0, 10); // Ambil YYYY-MM-DD saja
          } else {
            ttlController.text = dateStr;
          }
        }
      }

      nomorHpController.text = widget.siswaData!['nomor_hp']?.toString() ?? '';
      nikController.text = widget.siswaData!['nik']?.toString() ?? '';
      alamatController.text = widget.siswaData!['alamat']?.toString() ?? '';

      // 2️⃣ Mapping data wilayah
      final wilayah = widget.siswaData!['wilayah'] ?? {};
      dusunController.text = wilayah['dusun']?.toString() ?? '';
      desaController.text = wilayah['desa']?.toString() ?? '';
      kecamatanController.text = wilayah['kecamatan']?.toString() ?? '';
      kabupatenController.text = wilayah['kabupaten']?.toString() ?? '';
      provinsiController.text = wilayah['provinsi']?.toString() ?? '';
      kodePosController.text = wilayah['kode_pos']?.toString() ?? '';

      // 3️⃣ Mapping data ortu
      final ortu = widget.siswaData!['ortu'] ?? {};
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
      final uniqueDusun = <String>{};
      
      for (var item in response as List) {
        final dusun = item['dusun']?.toString();
        if (dusun != null && dusun.isNotEmpty) {
          uniqueDusun.add(dusun);
        }
      }
      
      setState(() {
        dusunList = uniqueDusun.toList()..sort();
      });
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠ Gagal fetch dusun: ${e.message}")),
        );
      }
    }
  }

  // Ambil data wilayah otomatis berdasarkan dusun yang dipilih
  Future<void> _fetchWilayahFromDusun(String dusun) async {
    try {
      final res = await client
          .from('wilayah')
          .select('*')
          .eq('dusun', dusun)
          .limit(1);

      if ((res as List).isNotEmpty) {
        final wilayah = res.first;
        setState(() {
          desaController.text = wilayah['desa']?.toString() ?? '';
          kecamatanController.text = wilayah['kecamatan']?.toString() ?? '';
          kabupatenController.text = wilayah['kabupaten']?.toString() ?? '';
          provinsiController.text = wilayah['provinsi']?.toString() ?? '';
          kodePosController.text = wilayah['kode_pos']?.toString() ?? '';
        });
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

    setState(() {
      _loading = true;
    });

    try {
      dynamic wilayahId = widget.siswaData?['wilayah_id'];
      dynamic siswaId = widget.siswaData?['id'];

      // 1️⃣ Insert/update wilayah
      final wilayahData = {
        'dusun': dusunController.text.trim(),
        'desa': desaController.text.trim(),
        'kecamatan': kecamatanController.text.trim(),
        'kabupaten': kabupatenController.text.trim(),
        'provinsi': provinsiController.text.trim(),
        'kode_pos': kodePosController.text.trim(),
      };

      if (widget.siswaData == null) {
        // Insert new wilayah
        final res = await client.from('wilayah').insert(wilayahData).select();
        wilayahId = (res as List).first['id'];
      } else if (wilayahId != null) {
        // Update existing wilayah
        await client.from('wilayah').update(wilayahData).eq('id', wilayahId);
      } else {
        // Create new wilayah for existing siswa (edge case)
        final res = await client.from('wilayah').insert(wilayahData).select();
        wilayahId = (res as List).first['id'];
      }

      // 2️⃣ Insert/update siswa
      final siswaData = {
        'nisn': nisnController.text.trim(),
        'nama_panjang': namaController.text.trim(),
        'jenis_kelamin': selectedJenisKelamin,
        'agama': agamaController.text.trim(),
        'tempat_lahir': ttlController.text.trim(),
        'nomor_hp': nomorHpController.text.trim(),
        'nik': nikController.text.trim(),
        'alamat': alamatController.text.trim(),
        'wilayah_id': wilayahId,
      };

      if (widget.siswaData == null) {
        // Insert new siswa
        final res = await client.from('siswa').insert(siswaData).select();
        siswaId = (res as List).first['id'];
      } else {
        // Update existing siswa
        await client.from('siswa').update(siswaData).eq('id', siswaId);
      }

      // 3️⃣ Insert/update ortu
      final ortuData = {
        'nama_ayah': ayahController.text.trim(),
        'nama_ibu': ibuController.text.trim(),
        'nama_wali': waliController.text.trim(),
        'alamat_wali': alamatWaliController.text.trim(),
        'siswa_id': siswaId,
      };

      if (widget.siswaData == null) {
        // Insert new ortu
        await client.from('ortu').insert(ortuData);
      } else {
        // Check if ortu exists, then update or insert
        final ortuList = await client.from('ortu').select('*').eq('siswa_id', siswaId);
        if ((ortuList as List).isEmpty) {
          await client.from('ortu').insert(ortuData);
        } else {
          await client.from('ortu').update(ortuData).eq('siswa_id', siswaId);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Data berhasil disimpan")),
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠ Gagal simpan: ${e.message}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠ Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _field(String label, TextEditingController c, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.blue[50],
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.siswaData == null ? "Tambah Siswa" : "Edit Siswa"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "=== Data Siswa ===",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _field("NISN", nisnController, keyboardType: TextInputType.number),
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
                          DateTime initialDate = DateTime.now();
                          if (ttlController.text.isNotEmpty) {
                            final parsed = DateTime.tryParse(ttlController.text);
                            if (parsed != null) initialDate = parsed;
                          }

                          final date = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            ttlController.text = date.toIso8601String().split('T').first;
                          }
                        },
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null,
                      ),
                    ),

                    _field("No HP", nomorHpController, keyboardType: TextInputType.phone),
                    _field("NIK", nikController, keyboardType: TextInputType.number),
                    _field("Alamat", alamatController),

                    const SizedBox(height: 16),
                    const Text(
                      "=== Data Wilayah ===",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    // Autocomplete Dusun
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.trim().isEmpty) return const Iterable<String>.empty();
                          return dusunList.where((dusun) =>
                              dusun.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          // Sync dengan dusunController
                          if (controller.text != dusunController.text) {
                            controller.text = dusunController.text;
                            controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length));
                          }

                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            onChanged: (value) {
                              dusunController.text = value;
                            },
                            decoration: InputDecoration(
                              labelText: 'Dusun',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.blue[50],
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null,
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
                    _field("Kode Pos", kodePosController, keyboardType: TextInputType.number),

                    const SizedBox(height: 16),
                    const Text(
                      "=== Data Orang Tua/Wali ===",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _field("Nama Ayah", ayahController),
                    _field("Nama Ibu", ibuController),
                    _field("Nama Wali", waliController),
                    _field("Alamat Wali", alamatWaliController),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Simpan", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    nisnController.dispose();
    namaController.dispose();
    jkController.dispose();
    agamaController.dispose();
    ttlController.dispose();
    nomorHpController.dispose();
    nikController.dispose();
    alamatController.dispose();
    dusunController.dispose();
    desaController.dispose();
    kecamatanController.dispose();
    kabupatenController.dispose();
    provinsiController.dispose();
    kodePosController.dispose();
    ayahController.dispose();
    ibuController.dispose();
    waliController.dispose();
    alamatWaliController.dispose();
    super.dispose();
  }
}