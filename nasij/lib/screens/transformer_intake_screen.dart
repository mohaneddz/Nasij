import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'qr_scanner_screen.dart';
import '../widgets/transformer_bottom_nav_bar.dart';
import '../utils/app_theme.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';

class TransformerIntakeScreen extends StatefulWidget {
  const TransformerIntakeScreen({super.key});

  @override
  State<TransformerIntakeScreen> createState() => _TransformerIntakeScreenState();
}

class _TransformerIntakeScreenState extends State<TransformerIntakeScreen> {
  final TextEditingController _weightController = TextEditingController();
  final BatchService _batchService = BatchService();
  Batch? _activeBatch;
  bool _showWeightForm = false;
  bool _isSubmitting = false;
  bool _isFetchingBatch = false;

  void _onScanQr() async {
    final scannedId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(title: 'Scan Washer QR'),
      ),
    );

    if (scannedId != null && mounted) {
      _fetchBatchDetails(scannedId);
    }
  }

  Future<void> _fetchBatchDetails(String batchId) async {
    setState(() => _isFetchingBatch = true);
    try {
      final batch = await _batchService.fetchBatch(batchId);
      if (batch.status != 'AT_D2_LAVAGE') {
        throw Exception('This batch is not ready for factory intake (Status: ${batch.status}). Expected AT_D2_LAVAGE.');
      }
      setState(() {
        _activeBatch = batch;
        _showWeightForm = true;
        _isFetchingBatch = false;
      });
    } catch (e) {
      setState(() => _isFetchingBatch = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submitWeight() {
    if (_activeBatch == null) return;

    final declaredWeight = _activeBatch!.weightCleanD2Kg ?? 0.0;
    final actualWeight = double.tryParse(_weightController.text) ?? 0.0;
    
    if (actualWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight'), backgroundColor: Colors.red),
      );
      return;
    }

    final diff = (declaredWeight - actualWeight).abs();

    if (diff > 100) {
      _showDiscrepancyDialog(declaredWeight, actualWeight);
    } else {
      _completeIntake(actualWeight);
    }
  }

  void _showDiscrepancyDialog(double declared, double actual) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.borderDark)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            const SizedBox(width: 12),
            Text(
              'Weight Discrepancy',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A significant discrepancy was detected between the washer\'s declared weight and factory intake.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildDialogStat('Washer Declared', '${declared.toStringAsFixed(1)} kg'),
            _buildDialogStat('Factory Intake', '${actual.toStringAsFixed(1)} kg'),
            const SizedBox(height: 24),
            Text(
              'This discrepancy will be flagged for administrative review.',
              style: GoogleFonts.inter(
                color: Colors.orangeAccent.withOpacity(0.8),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeIntake(actual);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withOpacity(0.1),
              foregroundColor: Colors.orangeAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
            ),
            child: Text('PROCEED', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _completeIntake(double actualWeight) async {
    if (_activeBatch == null) return;
    
    setState(() => _isSubmitting = true);
    try {
      await _batchService.transformIntake(_activeBatch!.batchId, {
        'weight_received_factory_kg': actualWeight,
        'action_timestamp': DateTime.now().toIso8601String(),
      });
      
      setState(() => _isSubmitting = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.darkSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.borderDark)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Intake Successful',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Batch ${_activeBatch!.batchId} has been added to the transformation queue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _showWeightForm = false;
                        _activeBatch = null;
                        _weightController.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('CONTINUE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                        _buildScannerCard(),
                        if (_showWeightForm) ...[
                          const SizedBox(height: 24),
                          _buildWeightForm(),
                        ],
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
            child: TransformerBottomNavBar(currentIndex: 0),
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
              const Icon(Icons.input_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Text(
                'Factory Intake',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.white,
                ),
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
          'Transformer Intake',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Scan Washer\'s D3/D4 bale QR and record factory intake weight.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'WASHER BALE SCAN',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _onScanQr,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _activeBatch != null ? Colors.greenAccent.withOpacity(0.3) : AppTheme.borderDark,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isFetchingBatch)
                    const CircularProgressIndicator(color: AppTheme.primaryOrange)
                  else ...[
                    Icon(
                      _activeBatch != null ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded,
                      size: 48,
                      color: _activeBatch != null ? Colors.greenAccent : Colors.white10,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _activeBatch != null ? _activeBatch!.batchId : 'Tap to scan D3 or D4 QR',
                      style: GoogleFonts.inter(
                        color: _activeBatch != null ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'FACTORY WEIGHT RECORD',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WASHER DECLARED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueAccent.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_activeBatch?.weightCleanD2Kg?.toStringAsFixed(1) ?? '0.0'} KG',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.info_outline_rounded, color: Colors.blueAccent.withOpacity(0.3)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            decoration: AppTheme.inputDecoration('ACTUAL WEIGHT (KG)', Icons.scale_rounded),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitWeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      'LOG FACTORY INTAKE',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

