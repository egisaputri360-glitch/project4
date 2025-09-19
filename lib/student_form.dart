import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentForm extends StatefulWidget {
  final Map<String, dynamic>? siswaData;
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
  bool _isLoadingWilayah = false; // Tambahan untuk loading wilayah

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
    if (widget.siswaData != null) {
      nisnController.text = widget.siswaData!['nisn']?.toString() ?? '';
      namaController.text = widget.siswaData!['nama_panjang']?.toString() ?? '';
      final jk = widget.siswaData!['jenis_kelamin']?.toString();
      jkController.text = jk ?? '';
      selectedJenisKelamin = jk;
      agamaController.text = widget.siswaData!['agama']?.toString() ?? '';

      final ttl = widget.siswaData!['tempat_lahir'];
      if (ttl != null && ttl.toString().isNotEmpty) {
        if (ttl is DateTime) {
          ttlController.text =
              "${ttl.year}-${ttl.month.toString().padLeft(2, '0')}-${ttl.day.toString().padLeft(2, '0')}";
        } else {
          final dateStr = ttl.toString();
          if (dateStr.contains('-') && dateStr.length >= 10) {
            ttlController.text = dateStr.substring(0, 10);
          } else {
            ttlController.text = dateStr;
          }
        }
      }

      nomorHpController.text = widget.siswaData!['nomor_hp']?.toString() ?? '';
      nikController.text = widget.siswaData!['nik']?.toString() ?? '';
      alamatController.text = widget.siswaData!['alamat']?.toString() ?? '';

      final wilayah = widget.siswaData!['wilayah'] ?? {};
      dusunController.text = wilayah['dusun']?.toString() ?? '';
      desaController.text = wilayah['desa']?.toString() ?? '';
      kecamatanController.text = wilayah['kecamatan']?.toString() ?? '';
      kabupatenController.text = wilayah['kabupaten']?.toString() ?? '';
      provinsiController.text = wilayah['provinsi']?.toString() ?? '';
      kodePosController.text = wilayah['kode_pos']?.toString() ?? '';

      final ortu = widget.siswaData!['ortu'] ?? {};
      ayahController.text = ortu['nama_ayah']?.toString() ?? '';
      ibuController.text = ortu['nama_ibu']?.toString() ?? '';
      waliController.text = ortu['nama_wali']?.toString() ?? '';
      alamatWaliController.text = ortu['alamat_wali']?.toString() ?? '';
    }

    _fetchDusunList();
  }
  
  // Fungsi baru untuk menampilkan Date Picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        ttlController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
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
          SnackBar(
            content: Text("⚠ Gagal fetch dusun: ${e.message}"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠ Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // FUNGSI BARU: Auto-fill wilayah berdasarkan dusun yang dipilih
  Future<void> _autoFillWilayahFromDusun(String dusun) async {
    if (dusun.trim().isEmpty) {
      // Reset semua field wilayah jika dusun kosong
      setState(() {
        desaController.clear();
        kecamatanController.clear();
        kabupatenController.clear();
        provinsiController.clear();
        kodePosController.clear();
      });
      return;
    }

    setState(() => _isLoadingWilayah = true);
    
    try {
      final response = await client
          .from('wilayah')
          .select('desa, kecamatan, kabupaten, provinsi, kode_pos')
          .eq('dusun', dusun)
          .limit(1);

      if (response.isNotEmpty) {
        final wilayahData = response.first;
        setState(() {
          desaController.text = wilayahData['desa']?.toString() ?? '';
          kecamatanController.text = wilayahData['kecamatan']?.toString() ?? '';
          kabupatenController.text = wilayahData['kabupaten']?.toString() ?? '';
          provinsiController.text = wilayahData['provinsi']?.toString() ?? '';
          kodePosController.text = wilayahData['kode_pos']?.toString() ?? '';
        });

        // Tampilkan notifikasi sukses
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Data wilayah berhasil terisi otomatis"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Jika tidak ada data wilayah ditemukan
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("ℹ️ Data wilayah untuk dusun '$dusun' tidak ditemukan"),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠ Gagal mengambil data wilayah: ${e.message}"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠ Terjadi kesalahan saat mengambil data wilayah: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingWilayah = false);
    }
  }

  Future<void> _fetchWilayahFromDusun(String dusun) async {
    if (dusun.trim().isEmpty) return;
    try {
      final res =
          await client.from('wilayah').select('*').eq('dusun', dusun).limit(1);
      if (res.isNotEmpty) {
        final wilayah = res.first;
        setState(() {
          desaController.text = wilayah['desa'] ?? '';
          kecamatanController.text = wilayah['kecamatan'] ?? '';
          kabupatenController.text = wilayah['kabupaten'] ?? '';
          provinsiController.text = wilayah['provinsi'] ?? '';
          kodePosController.text = wilayah['kode_pos']?.toString() ?? '';
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠ Gagal ambil wilayah: ${e.message}"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠ Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Step 1: Simpan data siswa ke tabel 'siswa'
      final siswaRes = await client.from('siswa').upsert({
        'nisn': nisnController.text,
        'nama_panjang': namaController.text,
        'jenis_kelamin': selectedJenisKelamin,
        'agama': agamaController.text,
        'tempat_lahir': ttlController.text,
        'nomor_hp': nomorHpController.text,
        'nik': nikController.text,
        'alamat': alamatController.text,
      }).select();

      // Memeriksa respons dari upsert siswa
      if (siswaRes.isEmpty) {
        throw Exception("Gagal menyimpan data siswa ke server.");
      }

      // Step 2: Simpan data orang tua/wali ke tabel 'ortu'
      await client.from('ortu').upsert({
        'nisn_siswa': nisnController.text,
        'nama_ayah': ayahController.text,
        'nama_ibu': ibuController.text,
        'nama_wali': waliController.text,
        'alamat_wali': alamatWaliController.text,
      });

      // Step 3: Simpan data wilayah ke tabel 'wilayah'
      await client.from('wilayah').upsert({
        'dusun': dusunController.text,
        'desa': desaController.text,
        'kecamatan': kecamatanController.text,
        'kabupaten': kabupatenController.text,
        'provinsi': provinsiController.text,
        'kode_pos': int.tryParse(kodePosController.text),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Data berhasil disimpan"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠ Gagal simpan data: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠ Terjadi kesalahan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.blueGrey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700])),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboardType,
      bool readOnly = false,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: () {
          if (label == "Tanggal Lahir") {
            _selectDate();
          }
        },
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: readOnly ? Colors.grey[200] : Colors.white,
        ),
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? "Wajib diisi" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(widget.siswaData == null ? "Tambah Siswa" : "Edit Siswa",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _sectionCard(title: "📌 Data Siswa", children: [
                      _field("NISN", nisnController,
                          keyboardType: TextInputType.number),
                      _field("Nama Panjang", namaController),
                      DropdownButtonFormField<String>(
                        value: selectedJenisKelamin,
                        items: const [
                          DropdownMenuItem(
                              value: 'Laki-laki', child: Text('Laki-laki')),
                          DropdownMenuItem(
                              value: 'Perempuan', child: Text('Perempuan')),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedJenisKelamin = value),
                        decoration: InputDecoration(
                          labelText: 'Jenis Kelamin',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) =>
                            value == null ? "Pilih jenis kelamin" : null,
                      ),
                      const SizedBox(height: 12),
                      _field("Agama", agamaController),
                      _field("Tanggal Lahir", ttlController, readOnly: true),
                      _field("No HP", nomorHpController,
                          keyboardType: TextInputType.phone),
                      _field("NIK", nikController,
                          keyboardType: TextInputType.number),
                      _field("Alamat", alamatController),
                    ]),
                    _sectionCard(title: "🌍 Data Wilayah", children: [
                      // AUTOCOMPLETE DUSUN DENGAN AUTO-FILL
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          return dusunList.where((String option) {
                            return option
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          dusunController.text = selection;
                          // PANGGIL FUNGSI AUTO-FILL WILAYAH
                          _autoFillWilayahFromDusun(selection);
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          // Pastikan textEditingController diinisialisasi
                          textEditingController.text = dusunController.text;
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: "Dusun",
                              labelStyle: GoogleFonts.poppins(),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              filled: true,
                              fillColor: Colors.white,
                              // Tambahkan suffix icon untuk loading
                              suffixIcon: _isLoadingWilayah 
                                  ? Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.blueAccent),
                                        ),
                                      ),
                                    )
                                  : Icon(Icons.location_on_outlined),
                            ),
                            onChanged: (value) {
                              dusunController.text = value;
                              // Auto-fill ketika user mengetik dan berhenti
                              if (value.trim().isNotEmpty) {
                                Future.delayed(Duration(milliseconds: 500), () {
                                  if (value == textEditingController.text) {
                                    _autoFillWilayahFromDusun(value);
                                  }
                                });
                              }
                            },
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? "Wajib diisi"
                                    : null,
                          );
                        },
                      ),
                      
                      _field("Desa", desaController, readOnly: true),
                      _field("Kecamatan", kecamatanController, readOnly: true),
                      _field("Kabupaten", kabupatenController, readOnly: true),
                      _field("Provinsi", provinsiController, readOnly: true),
                      _field("Kode Pos", kodePosController,
                          keyboardType: TextInputType.number, readOnly: true),
                    ]),
                    _sectionCard(title: "👨‍👩‍👧‍👦 Data Orang Tua/Wali", children: [
                      _field("Nama Ayah", ayahController),
                      _field("Nama Ibu", ibuController),
                      _field("Nama Wali", waliController),
                      _field("Alamat Wali", alamatWaliController),
                    ]),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text("💾 Simpan",
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}