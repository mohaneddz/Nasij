import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/depot_bottom_nav_bar.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import '../utils/app_theme.dart';

class DepotProcessingScreen extends StatefulWidget {
  const DepotProcessingScreen({super.key});

  @override
  State<DepotProcessingScreen> createState() => _DepotProcessingScreenState();
}

class _DepotProcessingScreenState extends State<DepotProcessingScreen> {
  final BatchService _batchService = BatchService();
  List<Batch> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final batches = await _batchService.fetchBatches(status: 'AT_D1_STOCKAGE');
      if (!mounted) return;
      setState(() {
        _batches = batches.where((b) => b.weightAfterHandcleanKg == null).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openCleaningForm(Batch batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CleaningFormModal(
        batch: batch,
        onComplete: () {
          Navigator.pop(context);
          _loadBatches();
        },
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
                        _buildSectionHeader('TO DO (CLEANING)'),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
                  )
                else if (_batches.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No lots to process',
                            style: GoogleFonts.inter(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildKanbanCard(_batches[index]),
                        childCount: _batches.length,
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
            child: DepotBottomNavBar(currentIndex: 1),
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
              const Icon(Icons.sync_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Text(
                'Processing',
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
          'Processing Board',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Manage intake lots, separate waste and skins, and perform consistency audits.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: Colors.white24,
      ),
    );
  }

  Widget _buildKanbanCard(Batch batch) {
    final hasSkin = batch.sourceType == 'C2';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  batch.batchId,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasSkin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
                  ),
                  child: Text(
                    'SKIN-ON',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.purpleAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.scale_rounded, color: Colors.white24, size: 16),
              const SizedBox(width: 10),
              Text(
                'Intake Weight: ${batch.weightAfterHandcleanKg ?? batch.weightRawE1Kg ?? 0} KG',
                style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openCleaningForm(batch),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange.withOpacity(0.05),
                foregroundColor: AppTheme.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppTheme.primaryOrange.withOpacity(0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'START CLEANING',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleaningFormModal extends StatefulWidget {
  final Batch batch;
  final VoidCallback onComplete;
  const _CleaningFormModal({required this.batch, required this.onComplete});

  @override
  State<_CleaningFormModal> createState() => _CleaningFormModalState();
}

class _CleaningFormModalState extends State<_CleaningFormModal> {
  int _step = 0; 
  final TextEditingController _wasteController = TextEditingController();
  final TextEditingController _skinController = TextEditingController();
  final TextEditingController _postCleanedController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _generatedDispatchId;

  void _nextStep() {
    final hasSkin = widget.batch.sourceType == 'C2';
    if (_step == 0) {
      if (hasSkin) {
        setState(() => _step = 1);
      } else {
        setState(() => _step = 2);
      }
    } else if (_step == 1) {
      setState(() {
        _step = 2;
        _generatedDispatchId = 'SKIN-${widget.batch.batchId}';
      });
    } else {
      _submitFinalAudit();
    }
  }

  void _submitFinalAudit() async {
    final postWeight = double.tryParse(_postCleanedController.text) ?? 0.0;
    if (postWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter wool weight'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await BatchService().d1Clean(
        widget.batch.batchId,
        {
          'weight_after_handclean_kg': postWeight,
          'waste_removed_kg': double.tryParse(_wasteController.text) ?? 0.0,
          'skin_removed_kg': double.tryParse(_skinController.text) ?? 0.0,
          'action_timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (mounted) {
        widget.onComplete();
        _showProcessingSuccess();
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

  void _showProcessingSuccess() {
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
              'PROCESSING COMPLETE',
              style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Batch has been cleaned and audited.',
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
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
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_step == 0) _buildCleaningStep(),
          if (_step == 1) _buildSkinStep(),
          if (_step == 2) _buildAuditStep(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : Text(_step == 2 ? 'COMPLETE & CERTIFY' : 'CONTINUE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleaningStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Manual Cleaning', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Log the removal of heavy dirt, straw, and feces.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 32),
        TextField(
          controller: _wasteController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          decoration: AppTheme.inputDecoration('WASTE REMOVED (KG)', Icons.delete_outline_rounded),
        ),
      ],
    );
  }

  Widget _buildSkinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Skin Routing', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Separate the wool from the skin and weigh the skins.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 32),
        TextField(
          controller: _skinController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          decoration: AppTheme.inputDecoration('SKIN WEIGHT (KG)', Icons.layers_outlined),
        ),
      ],
    );
  }

  Widget _buildAuditStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Final Audit: Consistency', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Weigh the isolated wool to check for abnormal drops.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 32),
        TextField(
          controller: _postCleanedController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          decoration: AppTheme.inputDecoration('ISOLATED WOOL WEIGHT (KG)', Icons.scale_rounded).copyWith(
            hintText: '0.0',
            hintStyle: GoogleFonts.inter(color: Colors.white10),
          ),
        ),
        if (_generatedDispatchId != null) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Colors.purpleAccent, size: 32),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXTERNAL DISPATCH CREATED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.purpleAccent, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('Raw Skins Ticket: $_generatedDispatchId', style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

