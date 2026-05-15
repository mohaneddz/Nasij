import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/connectivity_cubit.dart';
import '../cubits/locale_cubit.dart';
import '../cubits/sync_cubit.dart';
import '../l10n/app_localizations.dart';
import '../routes/app_routes.dart';
import '../widgets/map_bottom_nav_bar.dart';
import '../widgets/supplier_bottom_nav_bar.dart';
import '../widgets/depot_bottom_nav_bar.dart';
import '../widgets/washer_bottom_nav_bar.dart';
import '../widgets/transformer_bottom_nav_bar.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppTheme.borderDark),
                                boxShadow: AppTheme.subtleShadow,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.tr('profile_title'),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Profile Info Card
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, authState) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurfaceLight,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.borderDark),
                                boxShadow: AppTheme.subtleShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1964&auto=format&fit=crop',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.person,
                                                  size: 32,
                                                  color: Colors.orange[200],
                                                ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          authState.userName ??
                                              l10n.tr('profile_user_default'),
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (authState.wilaya.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 13,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  authState.wilaya,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.orange,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          authState.userEmail ?? authState.phoneNumber,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white38,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, authState) {
                            if (authState.authMode != AuthMode.supplier) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.borderDark),
                                boxShadow: AppTheme.subtleShadow,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n
                                          .tr('profile_trust_score')
                                          .replaceAll(
                                            '{score}',
                                            '${authState.trustScore}',
                                          ),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Language Selector
                        _LanguageSelector(),

                        const SizedBox(height: 24),

                        // Connectivity Status Card
                        BlocBuilder<ConnectivityCubit, ConnectivityState>(
                          builder: (context, connState) {
                            final isOnline = connState.isOnline;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.borderDark),
                                boxShadow: AppTheme.subtleShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isOnline
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      isOnline ? Icons.wifi : Icons.wifi_off,
                                      color: isOnline
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isOnline
                                              ? l10n.tr(
                                                  'profile_connection_online',
                                                )
                                              : l10n.tr(
                                                  'profile_connection_offline',
                                                ),
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isOnline
                                              ? l10n.tr(
                                                  'profile_connection_online_desc',
                                                )
                                              : l10n.tr(
                                                  'profile_connection_offline_desc',
                                                ),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isOnline
                                          ? Colors.green[500]
                                          : Colors.red[400],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Data & Connectivity Section Header
                        Text(
                          l10n.tr('profile_data_connectivity'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white38,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sync Status Card (live from SyncCubit)
                        BlocBuilder<SyncCubit, SyncState>(
                          builder: (context, syncState) {
                            final pending = syncState.pendingCount;
                            final isSyncing =
                                syncState.status == SyncStatus.syncing;
                            final isSynced =
                                syncState.status == SyncStatus.synced &&
                                pending == 0;

                            Color dotColor;
                            if (isSynced) {
                              dotColor = Colors.green[500]!;
                            } else if (isSyncing) {
                              dotColor = Colors.blue[500]!;
                            } else {
                              dotColor = Colors.orange[500]!;
                            }

                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurfaceLight,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.borderDark),
                                boxShadow: AppTheme.subtleShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.cloud_sync_outlined,
                                      color: Colors.orangeAccent,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.tr('profile_sync_status'),
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                l10n
                                                    .tr('profile_offline_queue')
                                                    .replaceAll(
                                                      '{count}',
                                                      '$pending',
                                                    ),
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white54,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (isSyncing)
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.blue[500],
                                                    ),
                                              )
                                            else
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: dotColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Manual sync trigger
                                  GestureDetector(
                                    onTap: isSyncing
                                        ? null
                                        : () => context
                                              .read<SyncCubit>()
                                              .syncNow(),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkSurface,
                                        border: Border.all(
                                          color: AppTheme.borderDark,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.sync,
                                        color: isSyncing
                                            ? Colors.white38
                                            : Colors.white70,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Log Out Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              await context.read<AuthCubit>().logout();
                              if (!context.mounted) return;
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.auth,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.red[500],
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              l10n.tr('profile_log_out'),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state.authMode == AuthMode.supplier) {
                  return const SupplierBottomNavBar(currentIndex: 2);
                } else {
                  switch (state.selectedWorkerRole) {
                    case WorkerRole.transformation:
                      return const TransformerBottomNavBar(currentIndex: 3);
                    case WorkerRole.depot:
                      return const DepotBottomNavBar(currentIndex: 3);
                    case WorkerRole.lavery:
                      return const WasherBottomNavBar(currentIndex: 2);
                    case WorkerRole.collector:
                    default:
                      return const MapBottomNavBar(currentIndex: 3);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderDark),
            boxShadow: AppTheme.subtleShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.language, color: Colors.orangeAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LangChip(
                      label: 'FR',
                      locale: const Locale('fr'),
                      currentLocale: localeState.locale,
                    ),
                    _LangChip(
                      label: 'AR',
                      locale: const Locale('ar'),
                      currentLocale: localeState.locale,
                    ),
                    _LangChip(
                      label: 'EN',
                      locale: const Locale('en'),
                      currentLocale: localeState.locale,
                    ),
                    _LangChip(
                      label: 'BR',
                      locale: const Locale('fr', 'BR'),
                      currentLocale: localeState.locale,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final Locale locale;
  final Locale currentLocale;

  const _LangChip({required this.label, required this.locale, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    final isActive = currentLocale == locale;
    return GestureDetector(
      onTap: () => context.read<LocaleCubit>().changeLocale(locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange : AppTheme.darkSurface,
          border: isActive ? null : Border.all(color: AppTheme.borderDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white54)),
      ),
    );
  }
}
