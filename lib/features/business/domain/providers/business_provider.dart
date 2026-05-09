import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/business_repository.dart';

final businessRepositoryProvider = Provider((ref) => BusinessRepository());

final queuesStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(businessRepositoryProvider).watchQueues();
});
