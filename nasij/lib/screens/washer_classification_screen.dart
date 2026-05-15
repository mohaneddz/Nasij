import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/washer_bottom_nav_bar.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import '../utils/app_theme.dart';

class WasherClassificationScreen extends StatefulWidget {
  final Batch? batch;
  final double? preWashWeight;
  final double? postWashWeight;
  final double? yieldPercent;

  const WasherClassificationScreen({
    super.key,
    this.batch,
    this.preWashWeight,
    this.postWashWeight,
    this.yieldPercent,
  });

  @override
  State<WasherClassificationScreen> createState() => _WasherClassificationScreenState();
}

class _WasherClassificationScreenState extends State<WasherClassificationScreen> {
  String _selectedGrade = 'D3'; // D3 or D4
  bool _isSubmitting = false;

  void _finalizeClassification() async {
    setState(() => _isSubmitting = true);
    
    // Map grade selection to backend expected values
    final finalDestination = _selectedGrade == 'D3' ? 'D3_TEXTILES' : 'D4_ENGRAIS';
    
    try {
      await BatchService().d2Wash(
        widget.batch!.batchId,
        {
          'weight_clean_d2_kg': widget.postWashWeight,
          'final_destination': finalDestination,
          'action_timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.darkSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.borderDark)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Classification Finalized',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Batch ${widget.batch!.batchId} has been classified as $_selectedGrade and moved to finished goods inventory.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('DONE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.batch == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_rounded, size: 80, color: Colors.white10),
              const SizedBox(height: 24),
              Text(
                'No Active Wash Selected',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a batch from the Wash Queue first.',
                style: GoogleFonts.inter(color: Colors.white38),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const WasherBottomNavBar(currentIndex: 2),
      );
    }

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
                        _buildProductionMetricsCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('QUALITY CLASSIFICATION'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildGradeOption('D3', 'Standard Quality', 'Common textile usage', Colors.blue),
                            const SizedBox(width: 16),
                            _buildGradeOption('D4', 'Premium Export', 'High-end fine wool', Colors.purpleAccent),
                          ],
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _finalizeClassification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSubmitting 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('FINISH & MOVE TO INVENTORY', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
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
              const Icon(Icons.category_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Text(
                'Classification',
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
          'Post-Wash Audit',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Review production yield and assign quality grade.',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white54, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildProductionMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRODUCTION SUMMARY',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),
          _buildMetricRow('Weight Before', '${widget.preWashWeight?.toStringAsFixed(1)} KG', Icons.scale_rounded),
          _buildMetricRow('Weight After', '${widget.postWashWeight?.toStringAsFixed(1)} KG', Icons.done_all_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: AppTheme.borderDark),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calculated Yield', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Text(
                  '${widget.yieldPercent?.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.greenAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1.2),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white24),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGradeOption(String grade, String title, String subtitle, Color color) {
    final bool isSelected = _selectedGrade == grade;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGrade = grade),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isSelected ? color : AppTheme.borderDark, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: isSelected ? color : Colors.white10, shape: BoxShape.circle),
                child: Text(grade, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white24, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              const SizedBox(height: 16),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: isSelected ? Colors.white : Colors.white54)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: Colors.white24)),
            ],
          ),
        ),
      ),
    );
  }
}

