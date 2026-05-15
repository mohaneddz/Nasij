import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubits/auth_cubit.dart';
import '../l10n/app_localizations.dart';
import '../screens/supplier_dashboard_screen.dart';
import '../screens/supplier_operations_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/app_theme.dart';

class SupplierBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const SupplierBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final supplierRole = context.read<AuthCubit>().state.selectedSupplierRole;

    return Container(
      height: 70 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: const Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BottomNavItem(
            icon: Icons.dashboard_outlined,
            label: l10n.tr('nav_home'),
            isActive: currentIndex == 0,
            onTap: () {
              if (currentIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        SupplierDashboardScreen(role: supplierRole),
                    transitionDuration: Duration.zero,
                  ),
                );
              }
            },
          ),
          _BottomNavItem(
            icon: Icons.format_list_bulleted,
            label: l10n.tr('nav_operations'),
            isActive: currentIndex == 1,
            onTap: () {
              if (currentIndex != 1) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        SupplierOperationsScreen(role: supplierRole),
                    transitionDuration: Duration.zero,
                  ),
                );
              }
            },
          ),
          _BottomNavItem(
            icon: Icons.person_outline,
            label: l10n.tr('nav_profile'),
            isActive: currentIndex == 2,
            onTap: () {
              if (currentIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation1, animation2) =>
                        const ProfileScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryOrange : Colors.white38;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
