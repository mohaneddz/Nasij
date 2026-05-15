import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/washer_bottom_nav_bar.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import 'washer_classification_screen.dart';
import '../utils/app_theme.dart';

class WasherWashQueueScreen extends StatefulWidget {
  const WasherWashQueueScreen({super.key});

  @override
  State<WasherWashQueueScreen> createState() => _WasherWashQueueScreenState();
}

class _WasherWashQueueScreenState extends State<WasherWashQueueScreen> {
  final BatchService _batchService = BatchService();
  List<Batch> _batches = [];
  bool _isLoading = true;
  final Map<String, String> _lotStatuses = {}; // 'pending', 'in_progress'

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      // AT_D2_LAVAGE = batches that have been received at the washer, awaiting wash
      final batches = await _batchService.fetchBatches(status: 'AT_D2_LAVAGE');
      setState(() {
        _batches = batches;
        for (var b in _batches) {
          _lotStatuses.putIfAbsent(b.batchId, () => 'pending');
        }
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

  void _showQrCode(String batchId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.borderDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Batch Identification', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: batchId,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            Text(batchId, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white70)),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.inter(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openWashForm(Batch batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WashFormModal(
        batch: batch,
        onStartWash: () {
          setState(() {
            _lotStatuses[batch.batchId] = 'in_progress';
          });
        },
        onCompleteWash: (preWeight, postWeight, yieldPercent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WasherClassificationScreen(
                batch: batch,
                preWashWeight: preWeight,
                postWashWeight: postWeight,
                yieldPercent: yieldPercent,
              ),
            ),
          ).then((_) => _loadBatches());
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
                        _buildSectionHeader('PENDING & ACTIVE LOTS'),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)))
                else if (_batches.isEmpty)
                  SliverFillRemaining(child: Center(child: Text('No batches in queue.', style: GoogleFonts.inter(color: Colors.white24))))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final batch = _batches[index];
                          final status = _lotStatuses[batch.batchId] ?? 'pending';
                          final isPending = status == 'pending';
                          
                          return _buildBatchCard(batch, isPending);
                        },
                        childCount: _batches.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: WasherBottomNavBar(currentIndex: 1),
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
              const Icon(Icons.local_laundry_service_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Text(
                'Wash Queue',
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
          'Washing Pipeline',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Track active wash cycles and record production data.',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white54, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1.2),
    );
  }

  Widget _buildBatchCard(Batch batch, bool isPending) {
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
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showQrCode(batch.batchId),
                    icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white38),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isPending ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      isPending ? 'PENDING' : 'WASHING',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isPending ? Colors.orange : Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ready for wash since: ${batch.actionTimestamp?.split('T')[0] ?? 'N/A'}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openWashForm(batch),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                foregroundColor: isPending ? Colors.orange : Colors.blueAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isPending ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3))),
              ),
              icon: Icon(isPending ? Icons.play_arrow_rounded : Icons.sync, size: 20),
              label: Text(
                isPending ? 'START WASH' : 'COMPLETE WASH',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WashFormModal extends StatefulWidget {
  final Batch batch;
  final VoidCallback onStartWash;
  final Function(double preWeight, double postWeight, double yieldPercent) onCompleteWash;

  const _WashFormModal({
    required this.batch,
    required this.onStartWash,
    required this.onCompleteWash,
  });

  @override
  State<_WashFormModal> createState() => _WashFormModalState();
}

class _WashFormModalState extends State<_WashFormModal> {
  int _step = 0; // 0: Start, 1: Complete
  final TextEditingController _preWeightController = TextEditingController();
  final TextEditingController _postWeightController = TextEditingController();

  void _nextStep() {
    if (_step == 0) {
      final preWeight = double.tryParse(_preWeightController.text) ?? 0.0;
      if (preWeight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter pre-wash weight'), backgroundColor: Colors.red));
        return;
      }
      widget.onStartWash();
      setState(() => _step = 1);
    } else {
      final preWeight = double.tryParse(_preWeightController.text) ?? 0.0;
      final postWeight = double.tryParse(_postWeightController.text) ?? 0.0;
      
      if (postWeight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter post-wash weight'), backgroundColor: Colors.red));
        return;
      }

      final yieldPercent = (postWeight / preWeight) * 100;
      Navigator.pop(context); 
      widget.onCompleteWash(preWeight, postWeight, yieldPercent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 32, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppTheme.borderDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 48, height: 4, decoration: BoxDecoration(color: AppTheme.borderDark, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 32),
          if (_step == 0) ...[
            Text('Start Wash Cycle', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Confirm weight before loading.', style: GoogleFonts.inter(color: Colors.white54)),
            const SizedBox(height: 32),
            TextField(
              controller: _preWeightController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: AppTheme.inputDecoration('Weight Before (KG)', Icons.scale_rounded),
            ),
          ] else ...[
            Text('Wash Complete', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Enter dry weight to calculate yield.', style: GoogleFonts.inter(color: Colors.white54)),
            const SizedBox(height: 32),
            TextField(
              controller: _postWeightController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: AppTheme.inputDecoration('Weight After (KG)', Icons.done_all_rounded),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _step == 0 ? 'START WASH' : 'COMPLETE WASH',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

