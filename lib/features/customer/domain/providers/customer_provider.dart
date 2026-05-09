import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

final activeQueuesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(customerRepositoryProvider).watchActiveQueues();
});

final myTicketsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(customerRepositoryProvider).watchMyTickets();
});

// Stream Provider dinamis untuk melacak pergerakan 1 antrian saja secara Live
final liveQueueProvider = StreamProvider.family<Map<String, dynamic>?, Map<String, String>>((ref, ids) {
  final businessId = ids['businessId']!;
  final queueId = ids['queueId']!;
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(businessId)
      .collection('queues')
      .doc(queueId)
      .snapshots()
      .map((doc) {
         if (doc.exists && doc.data() != null) return {'id': doc.id, ...doc.data()!};
         return null;
      });
});
