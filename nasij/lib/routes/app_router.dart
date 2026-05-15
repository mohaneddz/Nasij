import 'package:flutter/material.dart';
import '../cubits/auth_cubit.dart';
import 'app_routes.dart';
import '../screens/auth_screen.dart';
import '../screens/collection_map_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/supplier_dashboard_screen.dart';
import '../screens/worker_dashboard_screen.dart';
import '../screens/depot_intake_screen.dart';
import '../screens/washer_intake_screen.dart';
import '../screens/transformer_intake_screen.dart';
import '../screens/profile_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(settings: settings, page: const SplashScreen());
      case AppRoutes.auth:
        return _buildRoute(settings: settings, page: const AuthScreen());
      case AppRoutes.farmerHome:
        return _buildRoute(
          settings: settings,
          page: const SupplierDashboardScreen(role: SupplierRole.farmer),
        );
      case AppRoutes.producerHome:
        return _buildRoute(
          settings: settings,
          page: const SupplierDashboardScreen(role: SupplierRole.producer),
        );
      case AppRoutes.slaughterhouseHome:
        return _buildRoute(
          settings: settings,
          page: const SupplierDashboardScreen(
            role: SupplierRole.slaughterhouse,
          ),
        );
      case AppRoutes.collectorHome:
        return _buildRoute(
          settings: settings,
          page: const CollectionMapScreen(),
        );
      case AppRoutes.depotHome:
        return _buildRoute(
          settings: settings,
          page: const DepotIntakeScreen(),
        );
      case AppRoutes.laveryHome:
        return _buildRoute(
          settings: settings,
          page: const WasherIntakeScreen(),
        );
      case AppRoutes.transformationHome:
        return _buildRoute(
          settings: settings,
          page: const TransformerIntakeScreen(),
        );
      case AppRoutes.profile:
        return _buildRoute(
          settings: settings,
          page: const ProfileScreen(),
        );
      default:
        return _buildRoute(
          settings: settings,
          page: Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  static PageRouteBuilder<dynamic> _buildRoute({
    required RouteSettings settings,
    required Widget page,
  }) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 550),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
