import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/business/presentation/screens/business_dashboard_screen.dart';
import '../../features/business/presentation/screens/business_registration_screen.dart';
import '../../features/customer/presentation/screens/customer_home_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/business-dashboard',
        name: 'business_dashboard',
        builder: (context, state) => const BusinessDashboardScreen(),
      ),
      GoRoute(
        path: '/business-registration',
        name: 'business_registration',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BusinessRegistrationScreen(queueData: extra);
        },
      ),
      GoRoute(
        path: '/customer-home',
        name: 'customer_home',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
    ],
  );
});
