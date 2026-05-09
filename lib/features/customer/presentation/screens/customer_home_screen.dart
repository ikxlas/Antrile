import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/providers/customer_provider.dart';
import 'package:digital_queue_app/core/utils/image_utils.dart';
import '../widgets/queue_audio_listener.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentIndex = 0;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return QueueAudioListener(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Ultra-soft off-white
      appBar: _currentIndex == 3 ? null : AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty ? currentUser!.displayName!.split(" ")[0] : 'Kawan'} !',
              style: const TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              _currentIndex == 0 ? 'Mau antri di mana hari ini?' : (_currentIndex == 1 ? 'Tiket aktif Anda' : 'Riwayat antrian Anda'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _BrowseQueuesTab(),
          _TicketsTab(isHistory: false),
          _TicketsTab(isHistory: true),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: const Color(0xFF0D5C53).withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10))
          ]
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFF0D5C53),
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10, height: 1.6, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, height: 1.6),
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.explore_rounded, size: 26), activeIcon: Icon(Icons.explore_rounded, size: 28), label: 'TELUSURI'),
              BottomNavigationBarItem(icon: Icon(Icons.confirmation_num_rounded, size: 26), activeIcon: Icon(Icons.confirmation_num_rounded, size: 28), label: 'TIKET SAYA'),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded, size: 26), activeIcon: Icon(Icons.history_rounded, size: 28), label: 'RIWAYAT'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 26), activeIcon: Icon(Icons.person_rounded, size: 28), label: 'PROFIL'),
            ],
          ),
        ),
      ),
    ));
  }
}

class _BrowseQueuesTab extends ConsumerWidget {
  const _BrowseQueuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeQueues = ref.watch(activeQueuesProvider);

    return activeQueues.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0B4D44))),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (queues) {
        if (queues.isEmpty) {
          return const _EmptyState(icon: Icons.search_off_rounded, title: 'Belum Ada Usaha', subtitle: 'Saat ini tidak ada layanan/loket yang terbuka.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: queues.length,
          itemBuilder: (context, index) {
             final queue = queues[index];
             int total = queue['totalNumber'] ?? 0;
             int current = queue['currentNumber'] ?? 0;
             List<dynamic> cancelledList = queue['cancelledTickets'] ?? [];
             int cancelledWaiting = cancelledList.where((n) => (n is int) && n > current).length;
             
             int waiting = total - current - cancelledWaiting;
             if (waiting < 0) waiting = 0;
             
             String loadStatus = 'Lancar';
             Color loadColor = const Color(0xFF10B981);
             if (waiting > 10) { loadStatus = 'Sangat Ramai'; loadColor = Colors.red.shade600; }
             else if (waiting > 4) { loadStatus = 'Cukup Sibuk'; loadColor = Colors.orange.shade600; }
             
             IconData businessIcon = Icons.storefront;
             String nameSlow = queue['name'].toString().toLowerCase();
             if (nameSlow.contains('klinik') || nameSlow.contains('sehat')) businessIcon = Icons.local_hospital;
             else if (nameSlow.contains('kopi') || nameSlow.contains('makan')) businessIcon = Icons.fastfood;

             return GestureDetector(
               onTap: () => _showBusinessDetail(context, ref, queue, waiting, loadStatus, loadColor, businessIcon),
               child: Container(
                 margin: const EdgeInsets.only(bottom: 24),
                 clipBehavior: Clip.antiAlias,
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(32), // More rounded premium feel
                   boxShadow: [
                      BoxShadow(color: const Color(0xFF0D5C53).withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12)),
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
                   ]
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Stack(
                       children: [
                         ClipRRect(
                           borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                           child: SafeImage.build(queue['imageUrl'], width: double.infinity, height: 160, fit: BoxFit.cover),
                         ),
                         // Premium Gradient Overlay
                         Container(
                           width: double.infinity, height: 160,
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               begin: Alignment.topCenter, end: Alignment.bottomCenter, 
                               colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.85)],
                               stops: const [0.0, 0.5, 1.0]
                             )
                           ),
                         ),
                         
                         Positioned(
                           bottom: 20, left: 24, right: 24,
                           child: Text(queue['name'] ?? 'Layanan', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                         ),
                         
                         // Floating Glassmorphism Badge
                         Positioned(
                           top: 20, right: 20,
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.95), 
                               borderRadius: BorderRadius.circular(30),
                               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                             ),
                             child: Row(children: [
                               Icon(businessIcon, size: 14, color: loadColor), 
                               const SizedBox(width: 6), 
                               Text(loadStatus, style: TextStyle(color: loadColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5))
                             ]),
                           ),
                         )
                       ],
                     ),
                     
                     Padding(
                       padding: const EdgeInsets.all(24),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text('STATUS LOKET SAAT INI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.0)),
                               const SizedBox(height: 8),
                               RichText(text: TextSpan(children: [
                                 TextSpan(text: 'Panggilan Ke-', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                                 TextSpan(text: '$current\n', style: const TextStyle(color: Color(0xFF0D5C53), fontSize: 18, fontWeight: FontWeight.w900, height: 1.5)),
                                 TextSpan(text: '$waiting antrian di belakang', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                               ]))
                             ],
                           ),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                             decoration: BoxDecoration(
                               gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0B4D44)]),
                               borderRadius: BorderRadius.circular(20),
                               boxShadow: [BoxShadow(color: const Color(0xFF0B4D44).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
                             ),
                             child: const Text('AMBIL\nTIKET', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, height: 1.2, letterSpacing: 1.0)),
                           )
                         ],
                       ),
                     )
                   ],
                 ),
               ),
             );
          },
        );
      },
    );
  }

  void _showBusinessDetail(BuildContext context, WidgetRef ref, Map<String, dynamic> queue, int waiting, String loadStatus, Color loadColor, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32))),
        child: Column(
          children: [
            Container(width: 50, height: 5, margin: const EdgeInsets.only(top: 16, bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(queue['businessId']).get(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final biz = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};
                  final desc = queue['description'] ?? biz['description'] ?? 'Tidak ada deskripsi dari pemilik antrian.';
                  final address = queue['address'] ?? biz['address'] ?? 'Tidak mencantumkan alamat lengkap';
                  final phone = queue['phone'] ?? biz['phone'] ?? 'Tidak cantumkan nomer telepon';
                  final email = biz['email'] ?? 'Tidak mencantumkan email';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Center(
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(16),
                             child: SafeImage.build(queue['imageUrl'], height: 120, width: 120, fit: BoxFit.cover),
                           ),
                         ),
                         const SizedBox(height: 16),
                         Center(child: Text(queue['name'] ?? 'Layanan', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827)))),
                         const SizedBox(height: 6),
                         Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: loadColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text('Kondisi: $loadStatus ($waiting menunggu)', style: TextStyle(color: loadColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                         ),
                         const SizedBox(height: 24), const Divider(), const SizedBox(height: 16),
                         const Text('Tentang Layanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                         const SizedBox(height: 8),
                         Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5)),
                         const SizedBox(height: 24),
                         Row(children: [Icon(Icons.location_on, size: 20, color: const Color(0xFF0D5C53)), const SizedBox(width: 12), Expanded(child: Text(address, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)))]),
                         const SizedBox(height: 12),
                         Row(children: [Icon(Icons.phone, size: 20, color: const Color(0xFF0D5C53)), const SizedBox(width: 12), Expanded(child: Text(phone, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)))]),
                         const SizedBox(height: 12),
                         Row(children: [Icon(Icons.email, size: 20, color: const Color(0xFF0D5C53)), const SizedBox(width: 12), Expanded(child: Text(email, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)))]),
                         const SizedBox(height: 120),
                      ],
                    ),
                  );
                }
              ),
            ),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4D44), padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmTakingTicket(context, ref, queue);
                },
                child: const Text('AMBIL NOMOR ANTRIAN', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _confirmTakingTicket(BuildContext context, WidgetRef ref, Map<String, dynamic> queue) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Tiket', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Anda akan memesan tiket di layanan\n\n"${queue['name']}"\n\nApakah Anda sudah siap menuju lokasi?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final nomor = await ref.read(customerRepositoryProvider).takeTicket(queue['businessId'], queue['id']);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil! Nomer Anda: $nomor'), backgroundColor: const Color(0xFF10B981)));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Ya, Ambil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }
}

class _TicketsTab extends ConsumerWidget {
  final bool isHistory;
  const _TicketsTab({required this.isHistory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTickets = ref.watch(myTicketsProvider);
    final activeQueues = ref.watch(activeQueuesProvider).value ?? [];

    return myTickets.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0B4D44))),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (tickets) {
        
        List<Map<String, dynamic>> displayedTickets = [];
        for (var t in tickets) {
          final queueMatch = activeQueues.where((q) => q['id'] == t['queueId']).toList();
          bool isActive = false;
          String statusStr = 'Riwayat';
          Color statusColor = Colors.grey;

          if (t['status'] == 'cancelled') {
             isActive = false;
             statusStr = 'Dibatalkan';
             statusColor = Colors.red.shade600;
          } else if (queueMatch.isEmpty) {
             isActive = false; // Loket sudah tutup
             statusStr = 'Loket Tutup / Selesai';
             statusColor = Colors.grey.shade600;
          } else {
             int qCurrent = queueMatch.first['currentNumber'] ?? 0;
             int qTotal = queueMatch.first['totalNumber'] ?? 0;
             int myNum = t['ticketNumber'] ?? 0;
             List<dynamic> completed = queueMatch.first['completedTickets'] ?? [];
             List<dynamic> skipped = queueMatch.first['skippedTickets'] ?? [];

             if (myNum > qTotal && qTotal == 0) {
                // BUG FIX: Jika pengusaha mereset antrian, totalNumber kembali ke 0.
                // Tiket lawas yang myNum-nya > 0 otomatis pindah ke riwayat sebagai Sesi Berakhir.
                isActive = false;
                statusStr = 'Sesi Antrian Direset';
                statusColor = Colors.grey.shade500;
             } else if (completed.contains(myNum)) {
                isActive = false;
                statusStr = 'Selesai Dilayani';
                statusColor = Colors.blue.shade600;
             } else if (skipped.contains(myNum)) {
                isActive = false;
                statusStr = 'Dilewati / Hangus';
                statusColor = Colors.grey.shade700;
             } else if (qCurrent > myNum) {
                // Berjaga-jaga jika pengusaha memanggil antrian selanjutnya tanpa memencet 'Selesai' atau 'Lewati'
                isActive = false;
                statusStr = 'Panggilan Terlewat';
                statusColor = Colors.grey.shade500;
             } else if (qCurrent == myNum) {
                isActive = true;
                statusStr = 'SEKARANG GILIRAN ANDA!';
                statusColor = Colors.green.shade700;
             } else {
                isActive = true;
                statusStr = 'Menunggu Panggilan';
                statusColor = Colors.orange.shade700;
             }
          }

          t['derivedStatus'] = statusStr;
          t['derivedColor'] = statusColor;
          t['isActive'] = isActive;

          if (isHistory && !isActive) displayedTickets.add(t);
          if (!isHistory && isActive) displayedTickets.add(t);
        }

        if (displayedTickets.isEmpty) {
          return _EmptyState(
             icon: isHistory ? Icons.history_edu_rounded : Icons.confirmation_num_outlined, 
             title: isHistory ? 'Belum Ada Riwayat' : 'Tiket Kosong', 
             subtitle: isHistory ? 'Anda belum memiliki riwayat pesanan yang selesai.' : 'Anda belum memesan antrian manapun/sedang aktif.'
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: displayedTickets.length,
          itemBuilder: (context, index) {
            final ticket = displayedTickets[index];
            return _buildBoardingPassTicket(context, ref, ticket, isHistory);
          },
        );
      },
    );
  }

  Widget _buildBoardingPassTicket(BuildContext context, WidgetRef ref, Map<String, dynamic> ticket, bool historyView) {
    bool isCancelled = ticket['status'] == 'cancelled';

    // Tentukan Gradient berdasarkan status
    LinearGradient headerGradient = const LinearGradient(colors: [Color(0xFF0D5C53), Color(0xFF0B4D44)]);
    if (historyView) {
      headerGradient = LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800]);
    } else if (ticket['derivedStatus'].toString().contains('SEKARANG GILIRAN ANDA')) {
      headerGradient = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)], 
        begin: Alignment.topLeft, end: Alignment.bottomRight
      );
    }
    
    return GestureDetector(
      onTap: () => _showTicketDetail(context, ref, ticket, !historyView),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        foregroundDecoration: isCancelled ? BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(24)) : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0D5C53).withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 12)),
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
          ]
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: headerGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28))
              ),
              child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TIKET LOKET', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(ticket['queueName'] ?? 'Loket Layanan', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: Icon(historyView ? Icons.history_rounded : Icons.confirmation_num_rounded, color: Colors.white, size: 28),
                  )
                ],
              ),
            ),
          ),
            // Dotted Separator with transparent holes
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  Container(width: 16, height: 32, decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.horizontal(right: Radius.circular(16)))),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Flex(
                        direction: Axis.horizontal, mainAxisAlignment: MainAxisAlignment.spaceBetween, mainAxisSize: MainAxisSize.max,
                        children: List.generate((constraints.constrainWidth() / 15).floor(), (index) => SizedBox(width: 8, height: 2, child: ColoredBox(color: Colors.grey.shade300))),
                      ),
                    ),
                  ),
                  Container(width: 16, height: 32, decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.horizontal(left: Radius.circular(16)))),
                ],
              ),
            ),
            
            // Bottom Section
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NOMOR URUT', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                      const SizedBox(height: 6),
                      Text('#${ticket['ticketNumber']}', style: const TextStyle(color: Color(0xFF111827), fontSize: 52, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -2)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: ticket['derivedColor'].withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: ticket['derivedColor'].withOpacity(0.2))),
                        child: Text(ticket['derivedStatus'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: ticket['derivedColor'])),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(children: List.generate(8, (index) => Container(width: [3.0, 5.0, 2.0, 6.0, 4.0, 2.0, 5.0, 1.0][index], height: 48, color: Colors.grey.shade800, margin: const EdgeInsets.only(right: 3)))),
                      const SizedBox(height: 10),
                      Text('DETAIL TIKET  ▶', style: TextStyle(color: Colors.grey.shade600, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ]
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showTicketDetail(BuildContext context, WidgetRef ref, Map<String, dynamic> ticket, bool showLiveTrackButton) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const Text('Detail Tiket Antrian', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 24),
            Container(
               width: double.infinity, padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(color: const Color(0xFFF7F9F0), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Layanan:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                   Text(ticket['queueName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                   const SizedBox(height: 16),
                   Text('Nomor Tiket Anda:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                   Text('#${ticket['ticketNumber']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: Color(0xFF0B4D44))),
                   const SizedBox(height: 16),
                   Text('Status Saat Ini:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                   Text(ticket['derivedStatus'], style: TextStyle(color: ticket['derivedColor'], fontWeight: FontWeight.bold, fontSize: 14)),
                 ],
               ),
            ),
            const SizedBox(height: 32),
            
            if (showLiveTrackButton && ticket['status'] != 'cancelled') ...[
              TextButton(
                onPressed: () async {
                   Navigator.pop(ctx);
                   await ref.read(customerRepositoryProvider).cancelTicket(ticket['queueId'], ticket['businessId'], ticket['ticketNumber']);
                   if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket berhasil dibatalkan'), backgroundColor: Colors.red));
                }, 
                child: const Text('Batalkan Tiket Ini', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
              )
            ] else ...[
               SizedBox(
                 width: double.infinity, height: 56,
                 child: ElevatedButton.icon(
                   icon: const Icon(Icons.delete),
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red.shade700, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                   onPressed: () {
                     showDialog(
                       context: context,
                       builder: (c) => AlertDialog(
                         title: const Text('Hapus Riwayat?'),
                         content: const Text('Apakah Anda yakin ingin menghapus tiket ini dari riwayat Anda?'),
                         actions: [
                           TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
                           TextButton(
                             onPressed: () async {
                               Navigator.pop(c); // tutup dialog
                               Navigator.pop(ctx); // tutup bottom sheet
                               await ref.read(customerRepositoryProvider).deleteHistoryTicket(ticket['id']);
                               if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Riwayat tiket dihapus')));
                             },
                             child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                           )
                         ]
                       )
                     );
                   },
                   label: const Text('Hapus Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
                 ),
               ),
               const SizedBox(height: 12),
               SizedBox(
                 width: double.infinity, height: 50,
                 child: OutlinedButton(
                   onPressed: () => Navigator.pop(ctx),
                   style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                   child: const Text('Tutup Panel'),
                 )
               )
            ],
            const SizedBox(height: 16)
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF0D5C53), Color(0xFF10B981)]),
              boxShadow: [BoxShadow(color: const Color(0xFF0D5C53).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]
            ),
            child: const CircleAvatar(radius: 56, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, size: 60, color: Color(0xFF0D5C53))),
          ),
        ),
        const SizedBox(height: 20),
        Text(user?.displayName ?? 'Pengguna', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -0.5)),
        Text(user?.email ?? 'email@domain.com', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 48),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0D5C53).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.help_outline_rounded, color: Color(0xFF0D5C53))), 
                title: const Text('Pusat Bantuan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey), onTap: (){},
              ),
              Divider(height: 1, color: Colors.grey.shade100, indent: 24, endIndent: 24),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0D5C53).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF0D5C53))), 
                title: const Text('Kebijakan Privasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey), onTap: (){},
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red.shade700, elevation: 0, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          icon: const Icon(Icons.logout_rounded), label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          onPressed: () async {
             await FirebaseAuth.instance.signOut();
             if (context.mounted) context.goNamed('login');
          },
        )
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)]), child: Icon(icon, size: 64, color: Colors.grey.shade300)),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5)),
        ],
      ),
    );
  }
}
