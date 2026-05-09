import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/business_provider.dart';

class QueueControllerScreen extends ConsumerWidget {
  final Map<String, dynamic> queueData;

  const QueueControllerScreen({super.key, required this.queueData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queuesAsync = ref.watch(queuesStreamProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Kontrol: ${queueData['name']}')),
      body: queuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (queues) {
          // Cari data antrian yang cocok agar halamannya me-refresh secara realtime sesuai cloud
          final queue = queues.firstWhere((q) => q['id'] == queueData['id'], orElse: () => queueData);
          final currentNumber = queue['currentNumber'] ?? 0;
          final totalNumber = queue['totalNumber'] ?? 0;
          final status = queue['status'] ?? 'active';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Column(
                    children: [
                      const Text('Nomor Antrian Saat Ini', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      Text(
                        currentNumber == 0 ? '-' : '$currentNumber',
                        style: const TextStyle(fontSize: 90, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text('Dari Total $totalNumber Antrian', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)), 
                        backgroundColor: status == 'active' ? Colors.green.shade100 : Colors.orange.shade100,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // BAGIAN 1: KONTROL TOTAL ANTRIAN (Walk-in & Batal)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ref.read(businessRepositoryProvider).actionCancelTicket(queue['id'], currentNumber, totalNumber);
                      }, 
                      icon: const Icon(Icons.person_remove, color: Colors.red), 
                      label: const Text('Batal 1 Tiket', style: TextStyle(color: Colors.red))
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(businessRepositoryProvider).actionAddWalkIn(queue['id']);
                      }, 
                      icon: const Icon(Icons.person_add), 
                      label: const Text('+ Walk-In Manual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // CONTROL BUTTONS GRID
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.keyboard_double_arrow_right,
                            label: 'Call Next',
                            color: const Color(0xFF10B981), // Emerald Premium
                            onTap: currentNumber >= totalNumber || status == 'paused' ? null : () {
                               ref.read(businessRepositoryProvider).actionCallNext(queue['id']);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.campaign,
                            label: 'Panggil Ulang',
                            color: const Color(0xFF3B82F6), // Blue 500
                            onTap: currentNumber == 0 ? null : () {
                               ref.read(businessRepositoryProvider).actionRecall(queue['id']);
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Memanggil Ulang Nomor $currentNumber...')));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.skip_next,
                            label: 'Lewati',
                            color: const Color(0xFF6B7280), // Gray 500
                            onTap: currentNumber >= totalNumber ? null : () {
                               ref.read(businessRepositoryProvider).actionSkip(queue['id']);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.check_circle_outline,
                            label: 'Selesaikan',
                            color: const Color(0xFF14B8A6), // Teal 500
                            onTap: currentNumber == 0 ? null : () async {
                               await ref.read(businessRepositoryProvider).actionComplete(queue['id']);
                               if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nomor $currentNumber Selesai. Memanggil berikut...')));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            icon: status == 'active' ? Icons.pause : Icons.play_arrow,
                            label: status == 'active' ? 'Standby/Jeda' : 'Lanjutkan',
                            color: Colors.orange,
                            onTap: () {
                              ref.read(businessRepositoryProvider).updateStatus(queue['id'], status == 'active' ? 'paused' : 'active');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.refresh,
                            label: 'Reset',
                            color: Colors.red,
                            onTap: () {
                               showDialog(
                                 context: context, 
                                 builder: (_) => AlertDialog(
                                   title: const Text('Reset Antrian?'),
                                   content: const Text('Semua nomor akan diulang dari 0.'),
                                   actions: [
                                     TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Batal')),
                                     TextButton(onPressed: (){
                                       ref.read(businessRepositoryProvider).actionReset(queue['id']);
                                       Navigator.pop(context);
                                     }, child: const Text('Hapus & Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                   ]
                                 )
                               );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      )
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
