import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/depot_intake_screen.dart';
import '../screens/depot_processing_screen.dart';
import '../screens/depot_inventory_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/app_theme.dart';

class DepotBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const DepotBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: const Border(top: BorderSide(color: AppTheme.borderDark, width: 1)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -4)),
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
                  icon: Icons.input_rounded,
                  label: 'Intake',
                  isActive: currentIndex == 0,
                  onTap: () {
                    if (currentIndex != 0) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) => const DepotIntakeScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.sync_rounded,
                  label: 'Processing',
                  isActive: currentIndex == 1,
                  onTap: () {
                    if (currentIndex != 1) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) => const DepotProcessingScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 70), // Space for center FAB
              Expanded(
                child: _NavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventory',
                  isActive: currentIndex == 2,
                  onTap: () {
                    if (currentIndex != 2) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) => const DepotInventoryScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: currentIndex == 3,
                  onTap: () {
                    if (currentIndex != 3) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) => const ProfileScreen(),
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
                  MaterialPageRoute(builder: (context) => const DepotIntakeScreen()),
                );
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.darkBackground, width: 4),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryOrange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
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
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryOrange : Colors.white24;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
              color: isActive ? Colors.white : Colors.white24,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

