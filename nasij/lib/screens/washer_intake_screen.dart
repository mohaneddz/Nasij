import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'qr_scanner_screen.dart';
import '../widgets/washer_bottom_nav_bar.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import '../utils/app_theme.dart';

class WasherIntakeScreen extends StatefulWidget {
  const WasherIntakeScreen({super.key});

  @override
  State<WasherIntakeScreen> createState() => _WasherIntakeScreenState();
}

class _WasherIntakeScreenState extends State<WasherIntakeScreen> {
  final BatchService _batchService = BatchService();
  Batch? _scannedBatch;
  bool _isLoading = false;

  void _onScanQr() async {
    final scannedId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(title: 'Scan Depot QR'),
      ),
    );

    if (scannedId != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final batch = await _batchService.fetchBatch(scannedId);
        setState(() {
          _scannedBatch = batch;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scan Failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _submitIntake() async {
    if (_scannedBatch == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _batchService.washerReceive(_scannedBatch!.batchId);
      
      setState(() {
        _isLoading = false;
        _scannedBatch = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch accepted and added to Wash Queue'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
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
                        _buildScannerArea(),
                        if (_scannedBatch != null) ...[
                          const SizedBox(height: 32),
                          _buildBatchDetailsCard(),
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
            child: WasherBottomNavBar(currentIndex: 0),
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
                'Washer Intake',
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
          'Receive Batch',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Scan the Depot QR to verify the batch and add it to the washing queue.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border.all(color: AppTheme.borderDark),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryOrange),
              const SizedBox(width: 10),
              Text(
                'QR SCANNER',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _onScanQr,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.2), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator(color: AppTheme.primaryOrange)
                  else
                    Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppTheme.primaryOrange.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _scannedBatch != null ? 'Batch: ${_scannedBatch!.batchId}' : 'Tap to Scan Depot QR',
                    style: GoogleFonts.inter(
                      color: _scannedBatch != null ? Colors.green[300] : Colors.white30,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchDetailsCard() {
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
            'BATCH DETAILS',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Batch ID', _scannedBatch!.batchId),
          _buildDetailRow('Source', _scannedBatch!.sourceType ?? 'C1'),
          _buildDetailRow('Origin', _scannedBatch!.wilaya ?? 'Unknown'),
          _buildDetailRow('Clean Weight', '${_scannedBatch!.weightAfterHandcleanKg ?? 0} KG'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: AppTheme.borderDark),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitIntake,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('ACCEPT & ADD TO QUEUE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

