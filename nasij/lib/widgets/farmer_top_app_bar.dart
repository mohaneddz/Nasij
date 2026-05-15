import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FarmerTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FarmerTopAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xCC0D1228), // 80% opacity
        border: Border(
          bottom: BorderSide(
            color: Color(0x1AFFFFFF), // white/10
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NASSAJ',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.6, // 0.2em roughly
                  color: const Color(0xFFF8FAFC), // slate-50
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFFF1F5F9), // slate-100
                ),
                splashRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64.0);
}
