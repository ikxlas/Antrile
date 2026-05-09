import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

// Provider yang memegang logika AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// State provider sederhana untuk mengontrol loading ring saat tombol di klik
class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool isLoading) {
    state = isLoading;
  }
}

final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(() {
  return AuthLoadingNotifier();
});
