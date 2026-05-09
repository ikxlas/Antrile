import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/business_profile.dart';

class BusinessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // Stream data profil usaha
  Stream<BusinessProfile?> watchProfile() {
    if (uid == null) return Stream.value(null);
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return BusinessProfile.fromMap(doc.data()!, doc.id);
    });
  }

  // Menyimpan data profil
  Future<void> saveProfile(BusinessProfile profile) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set(
      profile.toMap(),
      SetOptions(merge: true),
    );
  }

  // Stream data antrian secara Real-Time ke Dashboard Pemilik Usaha
  Stream<List<Map<String, dynamic>>> watchQueues() {
    if (uid == null) return const Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('queues')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });
  }

  // Membuat Lokasi Loket / Layanan Baru (Contoh: "Poli Gigi")
  Future<void> createQueue(String name) async {
    if (uid == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _firestore.collection('users').doc(uid).collection('queues').add({
      'name': name,
      'currentNumber': 0,
      'totalNumber': 0,
      'status': 'active', // active, paused, closed
      'lastResetDate': dateStr, // Sebagai acuan Auto-Reset besok harinya
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Mendaftarkan Usaha Baru dengan data lengkap (termasuk foto, deskripsi, dll)
  Future<void> registerBusiness(Map<String, dynamic> businessData) async {
    if (uid == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _firestore.collection('users').doc(uid).collection('queues').add({
      ...businessData,
      'currentNumber': 0,
      'totalNumber': 0,
      'status': 'active', // active, paused, closed
      'lastResetDate': dateStr,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Mengubah data Usaha (Edit)
  Future<void> updateBusiness(String queueId, Map<String, dynamic> businessData) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('queues').doc(queueId).update(businessData);
  }

  // Menghapus data Usaha (Delete)
  Future<void> deleteBusiness(String queueId) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('queues').doc(queueId).delete();
  }

  // Panggil Selanjutnya (Increment otomatis lewati yang dibatalkan)
  Future<void> actionCallNext(String queueId) async {
    if (uid == null) return;
    final docRef = _firestore.collection('users').doc(uid).collection('queues').doc(queueId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      int currentNum = doc.data()?['currentNumber'] ?? 0;
      int totalNum = doc.data()?['totalNumber'] ?? 0;
      if (currentNum >= totalNum) return;
      
      List<dynamic> cancelled = doc.data()?['cancelledTickets'] ?? [];
      int next = currentNum + 1;
      while (cancelled.contains(next) && next <= totalNum) {
        next++;
      }
      if (next > totalNum) next = totalNum;
      
      transaction.update(docRef, {
         'currentNumber': next,
         'callTriggerTime': FieldValue.serverTimestamp() // Pemicu pembaruan stream untuk Panggil Ulang
      });
    });
  }
  
  // Panggil Ulang
  Future<void> actionRecall(String queueId) async {
    if (uid == null) return;
    final docRef = _firestore.collection('users').doc(uid).collection('queues').doc(queueId);
    await docRef.update({
      'callTriggerTime': FieldValue.serverTimestamp()
    });
  }

  // Lewati / Skip
  Future<void> actionSkip(String queueId) async {
    if (uid == null) return;
    final docRef = _firestore.collection('users').doc(uid).collection('queues').doc(queueId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      int currentNum = doc.data()?['currentNumber'] ?? 0;
      int totalNum = doc.data()?['totalNumber'] ?? 0;
      if (currentNum >= totalNum) return;
      
      int targetSkipped = currentNum + 1; // Nomor yang dilewati (sebelum di-fast-forward)
      
      List<dynamic> cancelled = doc.data()?['cancelledTickets'] ?? [];
      int next = currentNum + 1;
      
      // Lompat cari valid berikutnya jika ternyata target berikutnya sudah keburu batal
      while (cancelled.contains(next) && next <= totalNum) {
        next++;
      }
      if (next > totalNum) next = totalNum;
      
      transaction.update(docRef, {
        'currentNumber': next,
        'skippedTickets': FieldValue.arrayUnion([targetSkipped])
      });
    });
  }

  // Selesaikan / Lengkapi
  Future<void> actionComplete(String queueId) async {
    if (uid == null) return;
    final docRef = _firestore.collection('users').doc(uid).collection('queues').doc(queueId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;
      
      int currentNum = doc.data()?['currentNumber'] ?? 0;
      int totalNum = doc.data()?['totalNumber'] ?? 0;
      if (currentNum == 0) return; // Tidak ada yang sedang dipanggil
      
      int targetCompleted = currentNum;
      
      List<dynamic> cancelled = doc.data()?['cancelledTickets'] ?? [];
      int next = currentNum + 1;
      
      // Lompat skip tiket yang sudah dibatalkan
      while (cancelled.contains(next) && next <= totalNum) {
        next++;
      }
      if (next > totalNum) next = totalNum;
      
      transaction.update(docRef, {
        'currentNumber': next,
        'completedTickets': FieldValue.arrayUnion([targetCompleted])
      });
    });
  }

  // Inject Walk-in Manual (Resepsionis mendaftarkan orang tanpa HP)
  Future<void> actionAddWalkIn(String queueId) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('queues').doc(queueId).update({
      'totalNumber': FieldValue.increment(1),
    });
  }

  // Batal Antri (Mengurangi jumlah orang yang mengantri/mundur)
  Future<void> actionCancelTicket(String queueId, int currentNum, int totalNum) async {
    if (uid == null || totalNum <= currentNum) return;
    await _firestore.collection('users').doc(uid).collection('queues').doc(queueId).update({
      'totalNumber': FieldValue.increment(-1), // Sistem paling sederhana: mencabut antrian terakhir
    });
  }

  // Reset Antrian (Kembali Ke 0)
  Future<void> actionReset(String queueId) async {
    if (uid == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _firestore.collection('users').doc(uid).collection('queues').doc(queueId).update({
      'currentNumber': 0,
      'totalNumber': 0,
      'lastResetDate': dateStr,
      'cancelledTickets': [],
      'skippedTickets': [],
      'completedTickets': [],
    });
  }
  
  // Pause / Resume
  Future<void> updateStatus(String queueId, String status) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('queues').doc(queueId).update({
      'status': status,
    });
  }
}
