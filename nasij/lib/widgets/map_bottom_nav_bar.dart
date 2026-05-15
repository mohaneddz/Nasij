import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../screens/collection_map_screen.dart';
import '../screens/my_loads_screen.dart';
import '../screens/prioritized_orders_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_colors.dart';

class MapBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const MapBottomNavBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, Widget destination, int index) {
    if (currentIndex == index) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 82 + bottomPad,
      padding: EdgeInsets.only(bottom: bottomPad + 8, top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              label: l10n.tr('nav_map'),
              isActive: currentIndex == 0,
              onTap: () => _navigate(context, const CollectionMapScreen(), 0),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.format_list_bulleted_rounded,
              activeIcon: Icons.format_list_bulleted_rounded,
              label: l10n.tr('nav_list'),
              isActive: currentIndex == 1,
              onTap: () =>
                  _navigate(context, const PrioritizedOrdersScreen(), 1),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.local_shipping_outlined,
              activeIcon: Icons.local_shipping,
              label: l10n.tr('nav_my_loads'),
              isActive: currentIndex == 2,
              onTap: () => _navigate(context, const MyLoadsScreen(), 2),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: l10n.tr('nav_profile'),
              isActive: currentIndex == 3,
              onTap: () => _navigate(context, const ProfileScreen(), 3),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 40 : 0,
            height: isActive ? 4 : 0,
            margin: EdgeInsets.only(bottom: isActive ? 6 : 0),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primary : AppColors.textFaint,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              letterSpacing: 0.3,
              color: isActive ? AppColors.primary : AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
