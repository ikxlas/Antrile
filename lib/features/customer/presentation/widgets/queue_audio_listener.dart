import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/providers/customer_provider.dart';

class QueueAudioListener extends ConsumerStatefulWidget {
  final Widget child;
  const QueueAudioListener({super.key, required this.child});

  @override
  ConsumerState<QueueAudioListener> createState() => _QueueAudioListenerState();
}

class _QueueAudioListenerState extends ConsumerState<QueueAudioListener> {
  final FlutterTts _flutterTts = FlutterTts();
  final Map<String, StreamSubscription<DocumentSnapshot>> _subscriptions = {};
  final Map<String, int> _lastCalledNumbers = {};
  final Map<String, String> _lastCallTriggers = {};

  @override
  void initState() {
    super.initState();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = ref.read(myTicketsProvider).value;
      if (initial != null) {
        _syncSubscriptions(initial);
      }
    });
  }
  
  Future<void> _initTts() async {
    try {
      // Coba setel ke ID jika Windows/OS/Chrome mendukungnya
      await _flutterTts.setLanguage("id-ID");
    } catch (e) {
      // Fallback: biarkan default sistem jika paket bahasa indonesianya tidak terinstall di PC/HP
    }
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  void _syncSubscriptions(List<Map<String, dynamic>> tickets) {
    final activeTicketIds = <String>{};
    
    for (var ticket in tickets) {
      if (ticket['status'] != 'cancelled') {
         final ticketId = ticket['id'] as String;
         activeTicketIds.add(ticketId);
         
         if (!_subscriptions.containsKey(ticketId)) {
            final bizId = ticket['businessId'].toString();
            final queueId = ticket['queueId'].toString();
            final myTicketNumber = int.tryParse(ticket['ticketNumber'].toString()) ?? 0;
            
            // Dengarkan pergerakan murni langsung dari firestore antrian utama
            _subscriptions[ticketId] = FirebaseFirestore.instance
                .collection('users')
                .doc(bizId)
                .collection('queues')
                .doc(queueId)
                .snapshots()
                .listen((doc) {
                if (doc.exists) {
                   final currentNumber = int.tryParse((doc.data()?['currentNumber'] ?? 0).toString()) ?? 0;
                   final lastCalled = _lastCalledNumbers[ticketId] ?? 0;
                   final currentTriggerTime = doc.data()?['callTriggerTime']?.toString() ?? '';
                   final lastTriggerTime = _lastCallTriggers[ticketId] ?? '';
                   
                   // Jika giliran customer kita, dan bukan perulangan panggilan lama (kecuali panggil ulang manual)
                   bool shouldCall = false;
                   if (currentNumber == myTicketNumber) {
                      if (currentNumber != lastCalled) shouldCall = true;
                      else if (currentTriggerTime.isNotEmpty && currentTriggerTime != lastTriggerTime) shouldCall = true;
                   }

                   if (shouldCall) {
                      _flutterTts.speak("Nomor urut Anda sedang dipanggil, silakan menuju loket.");
                   }
                   
                   _lastCalledNumbers[ticketId] = currentNumber;
                   _lastCallTriggers[ticketId] = currentTriggerTime;
                }
            });
         }
      }
    }
    
    // Putuskan mendengarkan loket jika tiket kita dibatalkan / dilewati / sudah selesai
    final keysToRemove = _subscriptions.keys.where((k) => !activeTicketIds.contains(k)).toList();
    for (var k in keysToRemove) {
      _subscriptions[k]?.cancel();
      _subscriptions.remove(k);
      _lastCalledNumbers.remove(k);
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Memaksa provider hidup dan terus dievaluasi
    final ticketsState = ref.watch(myTicketsProvider);
    
    if (ticketsState is AsyncData && ticketsState.value != null) {
       Future.microtask(() {
          if (mounted) {
             _syncSubscriptions(ticketsState.value!);
          }
       });
    }
    
    return widget.child;
  }
}
