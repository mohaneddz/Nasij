import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/washer_bottom_nav_bar.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import '../utils/app_theme.dart';

class WasherFinishedBalesScreen extends StatefulWidget {
  const WasherFinishedBalesScreen({super.key});

  @override
  State<WasherFinishedBalesScreen> createState() => _WasherFinishedBalesScreenState();
}

class _WasherFinishedBalesScreenState extends State<WasherFinishedBalesScreen> {
  final BatchService _batchService = BatchService();
  List<Batch> _d3Bales = [];
  List<Batch> _d4Bales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBales();
  }

  Future<void> _loadBales() async {
    setState(() => _isLoading = true);
    try {
      // After d2-wash the batch is AT_D2_LAVAGE with final_destination set
      final batches = await _batchService.fetchBatches(status: 'AT_D2_LAVAGE');
      setState(() {
        _d3Bales = batches.where((b) => b.finalDestination == 'D3_TEXTILES').toList();
        _d4Bales = batches.where((b) => b.finalDestination == 'D4_ENGRAIS').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBaleQR(Batch batch) {
    final isD3 = batch.classification == 'D3';
    final accentColor = isD3 ? Colors.greenAccent : Colors.purpleAccent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        title: Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: accentColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${batch.classification} Bale QR',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: batch.batchId,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bale ID: ${batch.batchId}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isD3 ? 'Premium Quality Wool' : 'Standard Fiber / Fertilizer',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('DONE', style: GoogleFonts.inter(color: AppTheme.primaryOrange, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildBaleCard(Batch batch) {
    final isD3 = batch.classification == 'D3';
    final accentColor = isD3 ? Colors.greenAccent : Colors.purpleAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  batch.batchId,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Text(
                  isD3 ? 'D3 QUALITY' : 'D4 STANDARD',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.scale_rounded, size: 16, color: Colors.white24),
              const SizedBox(width: 8),
              Text(
                'Weight: ${batch.weightCleanD2Kg?.toStringAsFixed(1) ?? '0.0'} KG',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showBaleQR(batch),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor.withOpacity(0.1),
                foregroundColor: accentColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: accentColor.withOpacity(0.3)),
                ),
              ),
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: Text(
                'GENERATE QR CODE',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildTitle(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)))
                else if (_d3Bales.isEmpty && _d4Bales.isEmpty)
                  SliverFillRemaining(child: Center(child: Text('No finished goods in inventory.', style: GoogleFonts.inter(color: Colors.white24))))
                else ...[
                  if (_d3Bales.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: _buildSectionHeader('D3 QUALITY BALES', Colors.greenAccent),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildBaleCard(_d3Bales[index]),
                          childCount: _d3Bales.length,
                        ),
                      ),
                    ),
                  ],
                  if (_d4Bales.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: _buildSectionHeader('D4 STANDARD BALES', Colors.purpleAccent),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildBaleCard(_d4Bales[index]),
                          childCount: _d4Bales.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WasherBottomNavBar(currentIndex: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Text(
                'Finished Goods',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bale Inventory',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Manage and generate identification tags for finished wool bales.',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white54, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color accent) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: accent.withOpacity(0.5), letterSpacing: 1.2),
    );
  }
}

