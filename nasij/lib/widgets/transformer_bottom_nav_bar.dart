import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/transformer_intake_screen.dart';
import '../screens/transformer_production_screen.dart';
import '../screens/transformer_finished_goods_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/app_theme.dart';

class TransformerBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const TransformerBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: 'Intake',
                  isActive: currentIndex == 0,
                  onTap: () {
                    if (currentIndex != 0) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation1, animation2) =>
                                  const TransformerIntakeScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.precision_manufacturing_outlined,
                  activeIcon: Icons.precision_manufacturing,
                  label: 'Production',
                  isActive: currentIndex == 1,
                  onTap: () {
                    if (currentIndex != 1) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation1, animation2) =>
                                  const TransformerProductionScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 70),
              Expanded(
                child: _NavItem(
                  icon: Icons.local_mall_outlined,
                  activeIcon: Icons.local_mall,
                  label: 'Finished',
                  isActive: currentIndex == 2,
                  onTap: () {
                    if (currentIndex != 2) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation1, animation2) =>
                                  const TransformerFinishedGoodsScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: currentIndex == 3,
                  onTap: () {
                    if (currentIndex != 3) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation1, animation2) =>
                                  const ProfileScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          Positioned(
            top: -25,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(title: 'Scan Washer QR'),
                  ),
                );
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.darkSurface, width: 4),
                  boxShadow: AppTheme.primaryGlow,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 30,
                ),
              ),
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
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppTheme.primaryOrange : Colors.white24,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? Colors.white : Colors.white24,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
