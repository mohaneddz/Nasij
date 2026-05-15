import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/depot_bottom_nav_bar.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import '../utils/app_theme.dart';

class DepotInventoryScreen extends StatefulWidget {
  const DepotInventoryScreen({super.key});

  @override
  State<DepotInventoryScreen> createState() => _DepotInventoryScreenState();
}

class _DepotInventoryScreenState extends State<DepotInventoryScreen> {
  final BatchService _batchService = BatchService();
  List<Batch> _batches = [];
  bool _isLoading = true;
  final List<String> _selectedLots = [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    try {
      final batches = await _batchService.fetchBatches(status: 'AT_D1_STOCKAGE');
      setState(() {
        // Show batches that have been cleaned but not yet shipped to D2
        _batches = batches.where((b) => b.weightAfterHandcleanKg != null).toList();
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

  void _toggleLot(String id) {
    setState(() {
      if (_selectedLots.contains(id)) {
        _selectedLots.remove(id);
      } else {
        _selectedLots.add(id);
      }
    });
  }

  void _createShipment() {
    if (_selectedLots.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryOrange, size: 48),
            const SizedBox(height: 24),
            Text(
              'Ship to Washer (D2)',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'You are about to consolidate ${_selectedLots.length} lots into a single outbound shipment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _batchService.shipBatches(_selectedLots);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadBatches();
                      _selectedLots.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shipment Dispatched'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('CONFIRM SHIPMENT', style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                        _buildSectionHeader('CLEANED LOTS IN STORAGE'),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 180),
                  sliver: _batches.isEmpty 
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              _isLoading ? 'Loading...' : 'No cleaned lots in storage',
                              style: GoogleFonts.inter(color: Colors.white38),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final batch = _batches[index];
                          final isSelected = _selectedLots.contains(batch.batchId);
                          return _buildLotCard(batch, isSelected);
                        }, childCount: _batches.length),
                      ),
                ),
              ],
            ),
          ),
          if (_selectedLots.isNotEmpty)
            Positioned(
              bottom: 110,
              left: 24,
              right: 24,
              child: _buildShipmentFab(),
            ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DepotBottomNavBar(currentIndex: 2),
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
                'Inventory',
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
          'Cleaned Stock',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'View cleaned wool and select lots to dispatch for industrial washing.',
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
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildLotCard(Batch batch, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleLot(batch.batchId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange.withOpacity(0.05) : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryOrange : AppTheme.borderDark, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppTheme.primaryOrange : Colors.white10, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.batchId,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cleaned Weight: ${batch.weightAfterHandcleanKg} KG',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                  ),
                ],
              ),
            ),
            if (batch.sourceType == 'C2')
              const Icon(Icons.layers_outlined, color: Colors.purple, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryOrange.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _createShipment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: const Icon(Icons.local_shipping_rounded),
        label: Text(
          'DISPATCH ${_selectedLots.length} LOTS',
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

