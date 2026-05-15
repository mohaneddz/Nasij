import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'qr_scanner_screen.dart';
import '../widgets/depot_bottom_nav_bar.dart';
import '../models/batch.dart';
import '../services/batch_service.dart';
import '../utils/app_theme.dart';

class DepotIntakeScreen extends StatefulWidget {
  final Batch? batch;
  const DepotIntakeScreen({super.key, this.batch});

  @override
  State<DepotIntakeScreen> createState() => _DepotIntakeScreenState();
}

class _DepotIntakeScreenState extends State<DepotIntakeScreen> {
  final TextEditingController _actualWeightController = TextEditingController();
  Batch? _scannedBatch;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scannedBatch = widget.batch;
  }

  void _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null) {
      _fetchBatch(result);
    }
  }

  Future<void> _fetchBatch(String id) async {
    setState(() => _isLoading = true);
    try {
      final batch = await BatchService().fetchBatch(id);
      setState(() {
        _scannedBatch = batch;
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

  void _submitReconciliation() async {
    if (_scannedBatch == null) return;
    
    final actualWeight = double.tryParse(_actualWeightController.text) ?? 0.0;
    if (actualWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight'), backgroundColor: Colors.red),
      );
      return;
    }

    final declaredWeight = _scannedBatch!.weightRawE1Kg ?? 0.0;
    final diff = declaredWeight - actualWeight;
    final lossPct = declaredWeight > 0 ? (diff / declaredWeight) * 100 : 0.0;

    if (lossPct > 20) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: AppTheme.borderDark)),
          backgroundColor: AppTheme.darkSurface,
          title: Column(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.primaryOrange, size: 48),
              const SizedBox(height: 16),
              Text(
                'Transit Loss Alert',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 24),
              ),
            ],
          ),
          content: Text(
            'The intake weight (${actualWeight}kg) shows a ${lossPct.toStringAsFixed(1)}% loss from the collector\'s declared weight (${declaredWeight}kg). Alert A1 will be triggered.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w900)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('PROCEED', style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await BatchService().d1Intake(
        _scannedBatch!.batchId,
        {
          'weight_received_d1_kg': actualWeight,
          'action_timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      setState(() {
        _isLoading = false;
        _scannedBatch = null;
        _actualWeightController.clear();
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: AppTheme.borderDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
            const SizedBox(height: 24),
            Text(
              'INTAKE COMPLETE',
              style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Lot has been moved to D1 Storage.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('FINISH', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
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
                        if (_scannedBatch == null) 
                          _buildScanPrompt()
                        else 
                          _buildReconciliationForm(),
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
            child: DepotBottomNavBar(currentIndex: 0),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
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
                'Depot Intake',
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
          'Receiving Audit',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Scan collector QR to validate receiving weight and check for transit loss.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildScanPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryOrange, size: 56),
          ),
          const SizedBox(height: 32),
          Text(
            'Ready to Scan?',
            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan the QR code on the collector\'s bag to begin the receiving audit.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _scanQR,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('SCAN COLLECTOR QR', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(32),
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
                'WEIGHT AUDIT',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLLECTOR DECLARED',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_scannedBatch!.weightRawE1Kg?.toStringAsFixed(1) ?? '0.0'} KG',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                Icon(Icons.check_circle_outline_rounded, color: Colors.blueAccent.withOpacity(0.5), size: 36),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _actualWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            decoration: AppTheme.inputDecoration('DEPOT INTAKE WEIGHT (KG)', Icons.scale_rounded).copyWith(
              hintText: '0.0',
              hintStyle: GoogleFonts.inter(color: Colors.white10),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReconciliation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('LOG DEPOT INTAKE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _scannedBatch = null),
              child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

