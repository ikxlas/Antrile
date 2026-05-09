import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/business_provider.dart';
import 'package:digital_queue_app/core/utils/image_utils.dart';
import 'queue_controller_screen.dart';
import 'business_settings_screen.dart';
import 'business_reports_view.dart';

class BusinessDashboardScreen extends ConsumerStatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  ConsumerState<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends ConsumerState<BusinessDashboardScreen> {
  int _selectedIndex = 0;
  String? firestorePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserPhoto();
  }

  void _loadUserPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()!['photoUrl'] != null) {
          if (mounted) {
            setState(() {
              firestorePhotoUrl = doc.data()!['photoUrl'];
            });
          }
        }
      } catch (e) {
        // ignore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final queuesAsync = ref.watch(queuesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8), // Background from design
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0B4D44),
        foregroundColor: Colors.white,
        onPressed: () => context.pushNamed('business_registration'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ]
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF0B4D44),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, height: 1.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, height: 1.5),
          onTap: (index) {
            if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessSettingsScreen())).then((_) {
                 _loadUserPhoto(); // Refresh on back
              });
            } else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'HOME'),
            BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined_rounded), label: 'LAPORAN'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'PENGATURAN'),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeView(queuesAsync),
            const BusinessReportsView(),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView(AsyncValue<List<Map<String, dynamic>>> queuesAsync) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTopCard(),
          _buildSectionTitle(),
          
          // Queue Cards based on stream
          queuesAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF0B4D44)),
            )),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (queues) {
              if (queues.isEmpty) {
                return _buildEmptyState();
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: queues.map((queue) => _buildQueueCard(queue)).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 80), // Padding for FAB
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = firestorePhotoUrl ?? user?.photoURL;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 75, height: 75),
              const SizedBox(width: 8),
              const Text(
                'Antrile',
                style: TextStyle(
                  color: Color(0xFF0D3B33),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessSettingsScreen())).then((_) {
                 _loadUserPhoto(); // Refresh on back
              });
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0B4D44),
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? SafeImage.getProvider(photoUrl) : null,
              child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D5C53),
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B4D44),
            Color(0xFF147A6B),
          ]
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B4D44).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Optimalkan\nOperasional Bisnis\nAnda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kelola semua antrian usaha Anda dari\nsatu dashboard terpusat. Cepat,\nefisien, dan profesional.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pushNamed('business_registration'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B4D44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.storefront, size: 20),
                SizedBox(width: 8),
                Text(
                  'DAFTARKAN USAHA BARU',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RINGKASAN PORTOFOLIO',
            style: TextStyle(
              color: const Color(0xFF0B4D44).withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Usaha Anda',
                style: TextStyle(
                  color: Color(0xFF0D3B33),
                  fontSize: 22,
                  fontWeight: FontWeight.bold, // Used w800 above, maybe consistency
                ),
              ),
              Row(
                children: const [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Color(0xFF0B4D44),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Color(0xFF0B4D44), size: 14),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> queue) {
    int totalNumber = queue['totalNumber'] ?? 0;
    int currentNumber = queue['currentNumber'] ?? 0;
    int activeQueue = currentNumber;
    
    String status = queue['status'] ?? 'active';
    bool isClosed = status == 'closed';
    
    double capacityValue = totalNumber > 0 ? (currentNumber / totalNumber).clamp(0.0, 1.0) : 0.0;
    int capacityPercentage = (capacityValue * 100).toInt();
    
    String statusLabel = isClosed ? 'TUTUP' : 'Aktif';
    Color statusColor = isClosed ? Colors.grey : const Color(0xFF10B981);
    
    IconData cardIcon = Icons.store;
    String tag = 'LAYANAN';
    String nameLower = queue['name'].toString().toLowerCase();
    
    if (nameLower.contains('klinik') || nameLower.contains('sehat') || nameLower.contains('gigi') || nameLower.contains('poli')) {
      cardIcon = Icons.medical_services;
      tag = 'KESEHATAN';
    } else if (nameLower.contains('kopi') || nameLower.contains('makan') || nameLower.contains('cafe')) {
      cardIcon = Icons.local_cafe;
      tag = 'F&B';
    } else if (nameLower.contains('barber') || nameLower.contains('cantik') || nameLower.contains('salon')) {
      cardIcon = Icons.content_cut;
      tag = 'KECANTIKAN';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QueueControllerScreen(queueData: queue)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Section
            Stack(
              children: [
                if (queue['imageUrl'] != null && queue['imageUrl'].toString().isNotEmpty)
                  SafeImage.build(
                    queue['imageUrl'],
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 160,
                    color: const Color(0xFF0D5C53),
                    child: Icon(cardIcon, color: Colors.white.withOpacity(0.3), size: 60),
                  ),
                
                // Gradient Overlay for Text Readability
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                
                // Tag
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Color(0xFF0B4D44),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                // Dropdown Menu Menu (Edit/Delete)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.pushNamed('business_registration', extra: queue);
                      } else if (value == 'delete') {
                        _showDeleteDialog(queue['id'], queue['name']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Usaha')),
                      const PopupMenuItem(value: 'delete', child: Text('Hapus Usaha', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
                
                // Business Name
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    queue['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Description
                  if (queue['description'] != null && queue['description'].toString().isNotEmpty) ...[
                    Text(
                      queue['description'],
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Contact Info
                  _buildContactRow(Icons.phone_outlined, queue['phone'] ?? 'Belum ada telepon'),
                  const SizedBox(height: 10),
                  _buildContactRow(Icons.email_outlined, queue['email'] ?? 'Belum ada email'),
                  const SizedBox(height: 10),
                  _buildContactRow(Icons.location_on_outlined, queue['address'] ?? 'Belum ada alamat'),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  
                  // Status Row
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isClosed ? 'Status Usaha: $statusLabel' : 'Antrian Dipanggil: $activeQueue',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  if (!isClosed) ...[
                     ClipRRect(
                       borderRadius: BorderRadius.circular(10),
                       child: LinearProgressIndicator(
                         value: capacityValue > 0 ? capacityValue : null,
                         minHeight: 8,
                         backgroundColor: const Color(0xFFE0F0EC),
                         valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D5C53)),
                       ),
                     ),
                     const SizedBox(height: 10),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           'KAPASITAS: $capacityPercentage%',
                           style: const TextStyle(
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                             color: Color(0xFF6B7280),
                           ),
                         ),
                         Text(
                           capacityPercentage > 80 ? 'SANGAT SIBUK' : (capacityPercentage > 40 ? 'SIBUK' : 'LANCAR'),
                           style: TextStyle(
                             fontSize: 10,
                             fontWeight: FontWeight.w800,
                             color: capacityPercentage > 80 ? Colors.red.shade700 : const Color(0xFF111827),
                             letterSpacing: 0.5,
                           ),
                         ),
                       ],
                     )
                  ] else ...[
                     const Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(
                           'ESTIMASI BUKA: BESOK JAM 09:00',
                           style: TextStyle(
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                             color: Color(0xFF6B7280),
                           ),
                         ),
                       ],
                     )
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0D5C53)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(String queueId, String businessName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Usaha?'),
        content: Text('Anda yakin ingin menghapus data usaha "$businessName"? Semua riwayat tidak dapat dikembalikan.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(businessRepositoryProvider).deleteBusiness(queueId);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Usaha',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan usaha/layanan pertama Anda.',
              style: TextStyle(color: Colors.grey.shade500),
            )
          ],
        ),
      ),
    );
  }
}
