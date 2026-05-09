import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // Stream semua layanan yang aktif menggunakan CollectionGroup
  Stream<List<Map<String, dynamic>>> watchActiveQueues() {
    return _firestore
        .collectionGroup('queues')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => doc.data()['status'] == 'active') // Filter manual melalui kode
              .map((doc) {
             return {
               'id': doc.id,
               'businessId': doc.reference.parent.parent?.id, // ID pemilik usaha
               ...doc.data()
             };
          }).toList();
        });
  }

  // Mengambil Tiket Antrian (Menggunakan Transaction agar aman walau banyak orang klik bersamaan)
  Future<int> takeTicket(String businessId, String queueId) async {
    if (uid == null) throw Exception("Tidak terautentikasi");
    
    final queueRef = _firestore.collection('users').doc(businessId).collection('queues').doc(queueId);
    final myTicketRef = _firestore.collection('users').doc(uid).collection('my_tickets').doc(queueId); 

    return await _firestore.runTransaction((transaction) async {
      final queueSnapshot = await transaction.get(queueRef);
      if (!queueSnapshot.exists) throw Exception("Antrian tidak ditemukan");

      final data = queueSnapshot.data()!;
      if (data['status'] != 'active') throw Exception("Mohon maaf, antrian sedang ditutup sementara");

      final newTotal = (data['totalNumber'] ?? 0) + 1;
      
      // Update Total Number di loket Usaha
      transaction.update(queueRef, {'totalNumber': newTotal});
      
      // Simpan bukti tiket ke dompet profil Pelanggan
      transaction.set(myTicketRef, {
         'queueId': queueId,
         'businessId': businessId,
         'queueName': data['name'],
         'ticketNumber': newTotal,
         'takenAt': FieldValue.serverTimestamp(),
      });

      return newTotal;
    });
  }

  // Melihat daftar tiket milik pelanggan ini
  Stream<List<Map<String, dynamic>>> watchMyTickets() {
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('my_tickets')
        .orderBy('takenAt', descending: true)
        .snapshots()
        .map((snapshot) {
           return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });
  }

  // Membatalkan tiket
  Future<void> cancelTicket(String queueId, String businessId, int ticketNumber) async {
    if (uid == null) throw Exception("Tidak terautentikasi");
    
    final batch = _firestore.batch();
    
    // 1. Update status tiket pribadi jadi dibatalkan
    final myTicketRef = _firestore.collection('users').doc(uid).collection('my_tickets').doc(queueId);
    batch.set(myTicketRef, {'status': 'cancelled'}, SetOptions(merge: true));
    
    // 2. Lempar nomor tiket yang dibatalkan ke koleksi antrian usaha agar sisa antrian (waiting) berkurang real-time
    final queueRef = _firestore.collection('users').doc(businessId).collection('queues').doc(queueId);
    batch.set(queueRef, {
      'cancelledTickets': FieldValue.arrayUnion([ticketNumber])
    }, SetOptions(merge: true));
    
    await batch.commit();
  }
  
  // Hapus tiket dari riwayat
  Future<void> deleteHistoryTicket(String ticketId) async {
    if (uid == null) throw Exception("Tidak terautentikasi");
    await _firestore.collection('users').doc(uid).collection('my_tickets').doc(ticketId).delete();
  }
}
