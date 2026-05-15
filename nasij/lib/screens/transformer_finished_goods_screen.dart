import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/transformer_bottom_nav_bar.dart';
import '../services/batch_service.dart';
import '../models/batch.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

class TransformerFinishedGoodsScreen extends StatefulWidget {
  const TransformerFinishedGoodsScreen({super.key});

  @override
  State<TransformerFinishedGoodsScreen> createState() => _TransformerFinishedGoodsScreenState();
}

class _TransformerFinishedGoodsScreenState extends State<TransformerFinishedGoodsScreen> {
  final BatchService _batchService = BatchService();
  List<Batch> _finishedGoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinishedGoods();
  }

  Future<void> _loadFinishedGoods() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final batches = await _batchService.fetchBatches(status: 'READY_FOR_SALE');
      if (!mounted) return;
      setState(() {
        _finishedGoods = batches.where((b) => b.isReadyForSale == true).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
                  )
                else if (_finishedGoods.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.white10, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No finished goods available.',
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
                        (context, index) {
                          return _buildProductCard(_finishedGoods[index]);
                        },
                        childCount: _finishedGoods.length,
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
            child: TransformerBottomNavBar(currentIndex: 2),
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
              const Icon(Icons.local_mall_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Text(
                'Warehouse',
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
          child: const Icon(Icons.search_rounded, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finished Goods',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Inventory of NFN Certified products ready for distribution.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Batch batch) {
    final isD3 = batch.finalDestination == 'D3_TEXTILES';
    final productType = batch.annexMetadata?['product_type'] ?? 'Unknown Product';
    final units = batch.annexMetadata?['total_units_produced']?.toString() ?? '0';
    final weight = batch.annexMetadata?['total_finished_weight_kg']?.toString() ?? '0';
    final date = batch.syncedAt != null 
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(batch.syncedAt!)) 
        : 'Recently';

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isD3 ? Colors.blueAccent : Colors.orangeAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (isD3 ? Colors.blueAccent : Colors.orangeAccent).withOpacity(0.2)),
                ),
                child: Text(
                  isD3 ? 'D3 PREMIUM' : 'D4 STANDARD',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isD3 ? Colors.blueAccent : Colors.orangeAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white24, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            productType,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'BATCH ID: ${batch.batchId}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatItem('UNITS', units, Icons.inventory_2_outlined),
              const SizedBox(width: 32),
              _buildStatItem('WEIGHT', '$weight KG', Icons.scale_rounded),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: AppTheme.borderDark, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                'NFN CERTIFIED',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.greenAccent.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryOrange.withOpacity(0.5), size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryOrange.withOpacity(0.7), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
