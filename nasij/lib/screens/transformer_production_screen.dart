import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/transformer_bottom_nav_bar.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import '../utils/app_theme.dart';

class TransformerProductionScreen extends StatefulWidget {
  const TransformerProductionScreen({super.key});

  @override
  State<TransformerProductionScreen> createState() => _TransformerProductionScreenState();
}

class _TransformerProductionScreenState extends State<TransformerProductionScreen> {
  final BatchService _batchService = BatchService();
  List<Batch> _availableLots = [];
  bool _isLoading = true;

  Batch? _selectedBatch;
  String? _selectedProduct;

  final TextEditingController _densityController = TextEditingController();
  final TextEditingController _fiberLengthController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _finishedWeightController = TextEditingController();

  final List<String> _d3Products = ['Insulation Panels', 'Geotextiles', 'Acoustic Rolls'];
  final List<String> _d4Products = ['Bio-fertilizer Pellets', 'Agricultural Mats'];

  List<String> get _currentProducts {
    if (_selectedBatch == null) return [];
    return (_selectedBatch!.finalDestination == 'D3_TEXTILES') ? _d3Products : _d4Products;
  }

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final batches = await _batchService.fetchBatches(status: 'IN_TRANSFORMATION');
      if (!mounted) return;
      setState(() {
        _availableLots = batches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _selectLot(Batch batch) {
    setState(() {
      _selectedBatch = batch;
      _selectedProduct = null;
    });
  }

  void _submitMetrics() {
    if (_selectedBatch == null || _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a lot and product type.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _openCertificationReview();
  }

  void _openCertificationReview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CertificationModal(
        batch: _selectedBatch!,
        product: _selectedProduct!,
        density: _densityController.text.isEmpty ? '35' : _densityController.text,
        fiberLength: _fiberLengthController.text.isEmpty ? '65' : _fiberLengthController.text,
        units: _unitsController.text.isEmpty ? '200' : _unitsController.text,
        finishedWeight: _finishedWeightController.text.isEmpty ? '2,800' : _finishedWeightController.text,
        onSeal: _sealAndCertify,
      ),
    );
  }

  void _sealAndCertify() async {
    final batchId = _selectedBatch!.batchId;
    Navigator.pop(context); // Close bottom sheet

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: const CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      ),
    );
    
    try {
      await _batchService.transform(
        batchId,
        {
          'product_type': _selectedProduct,
          'target_density_kg_m3': double.tryParse(_densityController.text) ?? 35.0,
          'fiber_length_mm': double.tryParse(_fiberLengthController.text) ?? 65.0,
          'total_units_produced': int.tryParse(_unitsController.text) ?? 200,
          'total_finished_weight_kg': double.tryParse(_finishedWeightController.text) ?? 2800.0,
          'action_timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessQR(batchId);
        setState(() {
          _selectedBatch = null;
          _selectedProduct = null;
          _densityController.clear();
          _fiberLengthController.clear();
          _unitsController.clear();
          _finishedWeightController.clear();
        });
        _loadBatches();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessQR(String batchId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: AppTheme.borderDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 64),
            const SizedBox(height: 24),
            Text(
              'NFN CERTIFIED',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commercial traceability QR generated successfully.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: QrImageView(
                data: 'NASIJ-CERT-$batchId',
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              batchId,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
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
                        _buildLotSelection(),
                        if (_selectedBatch != null) ...[
                          const SizedBox(height: 24),
                          _buildManufacturingForm(),
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
            child: TransformerBottomNavBar(currentIndex: 1),
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
              const Icon(Icons.precision_manufacturing_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Text(
                'Production Stage',
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
          child: const Icon(Icons.tune_rounded, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manufacturing Metrics',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Input final product specifications and certify the batch for commercial use.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT LOT FROM INVENTORY',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white24,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
        else if (_availableLots.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No bales in transformation queue.',
                    style: GoogleFonts.inter(color: Colors.white24, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableLots.length,
              itemBuilder: (context, index) {
                final batch = _availableLots[index];
                final isSelected = _selectedBatch?.batchId == batch.batchId;
                return GestureDetector(
                  onTap: () => _selectLot(batch),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryOrange.withOpacity(0.05) : AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryOrange : AppTheme.borderDark,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          batch.batchId,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${batch.weightCleanD2Kg ?? 0} KG',
                          style: GoogleFonts.inter(
                            color: isSelected ? AppTheme.primaryOrange : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildManufacturingForm() {
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
              const Icon(Icons.list_alt_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'PRODUCT SPECIFICATIONS',
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
          _buildDropdownField(),
          const SizedBox(height: 24),
          TextField(
            controller: _densityController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            decoration: AppTheme.inputDecoration('TARGET DENSITY (KG/M³)', Icons.monitor_weight_outlined),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fiberLengthController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            decoration: AppTheme.inputDecoration('FIBER LENGTH AVG (MM)', Icons.straighten_rounded),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _unitsController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            decoration: AppTheme.inputDecoration('TOTAL UNITS PRODUCED', Icons.numbers_rounded),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _finishedWeightController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            decoration: AppTheme.inputDecoration('TOTAL FINISHED WEIGHT (KG)', Icons.scale_rounded),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitMetrics,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'REVIEW & CERTIFY',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FINAL PRODUCT TYPE',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white24,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProduct,
              isExpanded: true,
              dropdownColor: AppTheme.darkSurface,
              hint: Text('Select Product', style: GoogleFonts.inter(color: Colors.white24, fontSize: 15, fontWeight: FontWeight.w600)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryOrange),
              items: _currentProducts.map((p) => DropdownMenuItem(
                value: p,
                child: Text(p, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedProduct = v),
            ),
          ),
        ),
      ],
    );
  }
}

class _CertificationModal extends StatelessWidget {
  final Batch batch;
  final String product;
  final String density;
  final String fiberLength;
  final String units;
  final String finishedWeight;
  final VoidCallback onSeal;

  const _CertificationModal({
    required this.batch,
    required this.product,
    required this.density,
    required this.fiberLength,
    required this.units,
    required this.finishedWeight,
    required this.onSeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Final Certification',
            style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Review metrics before sealing and generating commercial codes.',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildReviewRow('Lot ID', batch.batchId),
          _buildReviewRow('Classification', batch.finalDestination == 'D3_TEXTILES' ? 'D3 (Premium)' : 'D4 (Standard)'),
          _buildReviewRow('Product Type', product),
          _buildReviewRow('Target Density', '$density kg/m³'),
          _buildReviewRow('Fiber Length', '$fiberLength mm'),
          _buildReviewRow('Units Produced', units),
          _buildReviewRow('Total Weight', '$finishedWeight KG'),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 40),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NFN CERTIFIED TRACEABILITY',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'End-to-end digital provenance secured.',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'SEAL & CERTIFY',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white38),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
