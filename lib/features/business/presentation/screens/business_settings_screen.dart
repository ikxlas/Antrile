import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:digital_queue_app/core/utils/image_utils.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  User? user;
  String? firestorePhotoUrl;
  bool _isLoadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      user = currentUser;
    });
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (doc.exists && doc.data()!['photoUrl'] != null) {
          setState(() {
            firestorePhotoUrl = doc.data()!['photoUrl'];
          });
        }
      } catch (e) {
        // Handle gracefully
      }
    }
  }

  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20); // Extrema compress
    if (image != null && user != null) {
      setState(() => _isLoadingAvatar = true);
      try {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        
        // Simpan Base64 aman ke Firestore
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'photoUrl': dataUrl,
        }, SetOptions(merge: true));
        
        setState(() {
          firestorePhotoUrl = dataUrl;
          _isLoadingAvatar = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui!')));
        }
      } catch (e) {
        setState(() => _isLoadingAvatar = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
        }
      }
    }
  }

  Future<void> _updateProfileName() async {
    final nameController = TextEditingController(text: user?.displayName ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil Pribadi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4D44)),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await user?.updateDisplayName(nameController.text.trim());
                await user?.reload();
                _loadUser();
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama berhasil diperbarui!')));
                }
              }
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final userName = user?.displayName ?? 'Pengusaha Pro';
    final userEmail = user?.email ?? 'pengusaha@email.com';
    final userPhoto = firestorePhotoUrl ?? user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text(
          'Profil & Pengaturan', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF111827))
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _updateProfilePicture,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0B4D44), width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFFE0F0EC),
                            backgroundImage: userPhoto != null && userPhoto.isNotEmpty ? SafeImage.getProvider(userPhoto) : null,
                            child: _isLoadingAvatar
                                ? const CircularProgressIndicator(color: Color(0xFF0B4D44))
                                : (userPhoto == null || userPhoto.isEmpty ? const Icon(Icons.person, size: 50, color: Color(0xFF0B4D44)) : null),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D5C53),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userEmail,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🌟 Akun Premium Aktif',
                      style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Settings Modules
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionTitle('MANAJEMEN AKUN'),
                   _buildSettingsCard([
                     _buildSettingsTile(Icons.person_outline, 'Edit Profil Pribadi', 'Ubah nama dan informasi kontak', onTap: () => _updateProfileName()),
                     _buildSettingsTile(Icons.lock_outline, 'Keamanan Akun', 'Ubah kata sandi dan PIN', onTap: () {}),
                     _buildSettingsTile(Icons.notifications_outlined, 'Pengaturan Notifikasi', 'Atur peringatan antrian', onTap: () {}),
                   ]),
                   
                   const SizedBox(height: 24),
                   
                   _buildSectionTitle('DUKUNGAN & LAINNYA'),
                   _buildSettingsCard([
                     _buildSettingsTile(Icons.help_outline, 'Pusat Bantuan', 'FAQ dan fitur live chat', onTap: () {}),
                     _buildSettingsTile(Icons.privacy_tip_outlined, 'Kebijakan Privasi', 'Baca persayaratan layanan', onTap: () {}),
                     _buildSettingsTile(Icons.star_outline, 'Beri Rating Aplikasi', 'Dukung kami di Play Store', onTap: () {}),
                   ]),
                   
                   const SizedBox(height: 32),
                   
                   // Logout Button
                   SizedBox(
                     width: double.infinity,
                     height: 56,
                     child: OutlinedButton.icon(
                       onPressed: () => _handleLogout(context),
                       icon: const Icon(Icons.logout, color: Colors.red),
                       label: const Text('Keluar dari Akun', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                       style: OutlinedButton.styleFrom(
                         side: const BorderSide(color: Colors.red, width: 1.5),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       ),
                     ),
                   ),
                   const SizedBox(height: 48),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF0B4D44), size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Log Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari sesi aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.goNamed('login');
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
