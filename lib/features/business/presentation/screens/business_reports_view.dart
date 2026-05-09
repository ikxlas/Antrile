import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/business_provider.dart';

class BusinessReportsView extends ConsumerWidget {
  const BusinessReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queuesAsync = ref.watch(queuesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      body: SafeArea(
        child: queuesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0B4D44))),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (queues) {
            if (queues.isEmpty) {
              return _buildEmptyState();
            }

            int totalCustomers = queues.fold(0, (sum, q) => sum + (q['totalNumber'] as int? ?? 0));
            int totalFinished = queues.fold(0, (sum, q) => sum + ((q['completedTickets'] as List<dynamic>?)?.length ?? 0));
            int totalCancelled = queues.fold(0, (sum, q) => sum + ((q['cancelledTickets'] as List<dynamic>?)?.length ?? 0));
            int totalSkipped = queues.fold(0, (sum, q) => sum + ((q['skippedTickets'] as List<dynamic>?)?.length ?? 0));
            
            Map<String, dynamic>? busiestQueue;
            int maxCustomers = -1;
            for (var q in queues) {
              int count = q['totalNumber'] ?? 0;
              if (count >= maxCustomers) {
                maxCustomers = count;
                busiestQueue = q;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Color(0xFF0B4D44), size: 32),
                      const SizedBox(width: 12),
                      const Text(
                        'Ringkasan Hari Ini',
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: 
                          FontWeight.w800, 
                          color: Color(0xFF0D3B33)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                     'Statistik performa semua layanan cabang Anda secara Real-Time.',
                     style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 30),
                  
                  // Main Stat Grid
                  Row(
                    children: [
                      Expanded(child: _buildMiniStat('Pelanggan', totalCustomers.toString(), Icons.people_alt, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniStat('Selesai', totalFinished > 0 ? totalFinished.toString() : '0', Icons.check_circle, Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMiniStat('Batal', totalCancelled.toString(), Icons.cancel, Colors.red)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniStat('Dilewati', totalSkipped.toString(), Icons.next_plan, Colors.orange)),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text('Performa Tertinggi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  if (busiestQueue != null && maxCustomers > 0)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0B4D44), Color(0xFF147A6B)]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0xFF0B4D44).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.star, color: Colors.amber, size: 36),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(busiestQueue['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('$maxCustomers Pelanggan terlayani', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  else
                     const Center(child: Text('Belum ada pelanggan terlayani hari ini.')),
                    
                  const SizedBox(height: 32),
                  const Text('Beban Kapasitas Loket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))]
                    ),
                    child: Column(
                      children: queues.map((q) => _buildProgressRow(q)).toList(),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildProgressRow(Map<String, dynamic> q) {
    int total = q['totalNumber'] ?? 0;
    int current = q['currentNumber'] ?? 0;
    double progress = total > 0 ? current / total : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(q['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('$current / $total', style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF0B4D44), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE0F0EC),
              valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.green : const Color(0xFF0B4D44)),
              minHeight: 8,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum Ada Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
