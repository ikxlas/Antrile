import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_queue_app/core/utils/image_utils.dart';
import '../../domain/providers/business_provider.dart';

class BusinessRegistrationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? queueData;
  const BusinessRegistrationScreen({super.key, this.queueData});

  @override
  ConsumerState<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends ConsumerState<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  Uint8List? _selectedImageBytes; // For rendering on web
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.queueData != null) {
      _nameController.text = widget.queueData!['name'] ?? '';
      _categoryController.text = widget.queueData!['category'] ?? '';
      _descController.text = widget.queueData!['description'] ?? '';
      _phoneController.text = widget.queueData!['phone'] ?? '';
      _emailController.text = widget.queueData!['email'] ?? '';
      _addressController.text = widget.queueData!['address'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? imageUrl;
    
    try {
      if (_selectedImageBytes != null) {
        final base64String = base64Encode(_selectedImageBytes!);
        // format as data URL so it loads in Image.network natively
        imageUrl = 'data:image/jpeg;base64,$base64String';
      } else if (widget.queueData != null) {
        imageUrl = widget.queueData!['imageUrl'];
      }

      final businessData = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'imageUrl': imageUrl, 
      };

      if (widget.queueData != null) {
        await ref.read(businessRepositoryProvider).updateBusiness(widget.queueData!['id'], businessData);
      } else {
        await ref.read(businessRepositoryProvider).registerBusiness(businessData);
      }

      if (mounted) {
        final msg = widget.queueData != null ? 'Usaha berhasil diedit!' : 'Usaha berhasil didaftarkan!';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        elevation: 0,
        titleSpacing: 4,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B4D44)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.queueData != null ? 'Edit Usaha' : 'Pendaftaran Usaha',
          style: const TextStyle(color: Color(0xFF111827), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageUploadArea(),
                const SizedBox(height: 30),
                
                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(label: 'NAMA USAHA', hint: 'Contoh: Kopi Senja Abadi', controller: _nameController),
                      _buildTextField(label: 'KATEGORI USAHA', hint: 'Contoh: Food & Beverage', controller: _categoryController),
                      _buildTextField(label: 'DESKRIPSI USAHA', hint: 'Ceritakan keunikan usaha Anda...', controller: _descController, maxLines: 3),
                      _buildTextField(label: 'NOMOR TELEPON / WHATSAPP', hint: '0812-xxxx-xxxx', controller: _phoneController, icon: Icons.phone, keyboardType: TextInputType.phone),
                      _buildTextField(label: 'EMAIL USAHA', hint: 'halo@usahaanda.com', controller: _emailController, icon: Icons.email, keyboardType: TextInputType.emailAddress),
                      _buildTextField(label: 'ALAMAT LENGKAP', hint: 'Jl. Sudirman No. 123, Jakarta Selatan...', controller: _addressController, icon: Icons.location_on, maxLines: 2),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B4D44),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(widget.queueData != null ? 'Simpan Perubahan' : 'Daftar Sekarang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Dengan mendaftar, Anda menyetujui\nSyarat & Ketentuan kami.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                _buildInfoCard(
                  icon: Icons.verified_user,
                  title: 'Data Terjamin',
                  desc: 'Informasi usaha Anda akan diverifikasi dalam waktu 1x24 jam.',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.show_chart,
                  title: 'Insight Bisnis',
                  desc: 'Dapatkan analitik pengunjung setelah pendaftaran disetujui.',
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadArea() {
    DecorationImage? imageDecoration;
    if (_selectedImageBytes != null) {
      imageDecoration = DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken));
    } else if (widget.queueData != null && widget.queueData!['imageUrl'] != null) {
      imageDecoration = DecorationImage(image: SafeImage.getProvider(widget.queueData!['imageUrl'])!, fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken));
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(24),
          image: imageDecoration,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF81D4C8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Color(0xFF0B4D44), size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unggah Foto Utama Usaha',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              'Format JPG, PNG. Maksimal 5MB.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: (v) => v!.isEmpty ? 'Atribut ini wajib diisi' : null,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0B4D44), size: 20) : null,
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD1EBE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0D5C53), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
