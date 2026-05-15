import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/locale_cubit.dart';
import '../l10n/app_localizations.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../utils/toast_utils.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _workerPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _workerPhoneFocusNode = FocusNode();
  final FocusNode _workerPasswordFocusNode = FocusNode();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  Timer? _otpTimer;
  bool _isSubmitting = false;
  String _lastSubmittedOtpCode = '';

  @override
  void dispose() {
    _otpTimer?.cancel();
    _phoneController.dispose();
    _workerPhoneController.dispose();
    _passwordController.dispose();
    _workerPhoneFocusNode.dispose();
    _workerPasswordFocusNode.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startOtpCountdown() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final authCubit = context.read<AuthCubit>();
      if (authCubit.state.otpResendSeconds <= 0) {
        _otpTimer?.cancel();
        return;
      }
      authCubit.tickOtpResendSeconds();
    });
  }

  String _currentOtpCode() {
    return _otpControllers.map((controller) => controller.text.trim()).join();
  }

  void _clearOtpCode() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    if (_otpFocusNodes.isNotEmpty) {
      _otpFocusNodes.first.requestFocus();
    }
  }

  Future<void> _handleContinue() async {
    if (_isSubmitting) return;
    final authCubit = context.read<AuthCubit>();
    final state = authCubit.state;
    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);

    try {
      if (state.authMode == AuthMode.supplier) {
        if (state.supplierAuthStage == SupplierAuthStage.phone) {
          authCubit.updatePhoneNumber(_phoneController.text);
          final errorKey = authCubit.validatePhone();
          if (errorKey != null) {
            ToastUtils.showError(context, l10n.tr(errorKey));
            return;
          }
          authCubit.advanceToOtpStage();
          authCubit.setOtpResendSeconds(60);
          _clearOtpCode();
          _startOtpCountdown();
          ToastUtils.showSuccess(context, l10n.tr('auth_otp_sent'));
          return;
        }

        if (state.supplierAuthStage == SupplierAuthStage.otp) {
          final otp = _currentOtpCode();
          if (otp.isEmpty) {
            ToastUtils.showError(context, l10n.tr('auth_error_empty_otp'));
            return;
          }
          if (otp.length != 6) {
            ToastUtils.showError(context, l10n.tr('auth_error_invalid_otp'));
            return;
          }

          try {
            _lastSubmittedOtpCode = otp;
            await authCubit.verifySupplierOtp(
              otp,
              requireWilayaForPending: true,
            );
            if (!mounted) return;
            if (authCubit.state.status == AuthStatus.pendingApproval) {
              _otpTimer?.cancel();
            }
          } catch (error) {
            if (!mounted) return;
            final message = _localizedErrorMessage(l10n, error);
            ToastUtils.showError(context, message);
          }
          return;
        }

        if (state.supplierAuthStage == SupplierAuthStage.wilaya) {
          if (state.wilaya.isEmpty) {
            ToastUtils.showError(context, l10n.tr('auth_error_select_wilaya'));
            return;
          }
          final otp = _lastSubmittedOtpCode.isNotEmpty
              ? _lastSubmittedOtpCode
              : _currentOtpCode();
          if (otp.isEmpty) {
            ToastUtils.showError(context, l10n.tr('auth_error_empty_otp'));
            return;
          }
          try {
            await authCubit.verifySupplierOtp(otp);
            if (!mounted) return;
            if (authCubit.state.status == AuthStatus.pendingApproval) {
              _otpTimer?.cancel();
            }
          } catch (error) {
            if (!mounted) return;
            final message = _localizedErrorMessage(l10n, error);
            ToastUtils.showError(context, message);
          }
        }
        return;
      }

      // Worker mode
      if (state.employeeAuthStep == 1) {
        authCubit.updateWorkerPhone(_workerPhoneController.text);
        final errorKey = authCubit.validateWorkerPhone();
        if (errorKey != null) {
          ToastUtils.showError(context, l10n.tr(errorKey));
          return;
        }
        FocusScope.of(context).unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        authCubit.nextAuthStep();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          FocusScope.of(context).requestFocus(_workerPasswordFocusNode);
        });
      } else {
        authCubit.updateWorkerPassword(_passwordController.text);
        final errorKey = authCubit.validatePassword();
        if (errorKey != null) {
          ToastUtils.showError(context, l10n.tr(errorKey));
          return;
        }
        try {
          await authCubit.login();
        } catch (error) {
          if (!mounted) return;
          final message = _localizedErrorMessage(l10n, error);
          ToastUtils.showError(context, message);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    final authCubit = context.read<AuthCubit>();
    final l10n = AppLocalizations.of(context);
    if (authCubit.state.otpResendSeconds > 0) return;

    try {
      await authCubit.requestSupplierOtp();
      _clearOtpCode();
      _startOtpCountdown();
      if (!mounted) return;
      ToastUtils.showSuccess(context, l10n.tr('auth_otp_resent'));
    } catch (error) {
      if (!mounted) return;
      ToastUtils.showError(context, _localizedErrorMessage(l10n, error));
    }
  }

  Future<void> _handlePendingStatusCheck() async {
    if (_isSubmitting) return;
    final authCubit = context.read<AuthCubit>();
    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);

    try {
      await authCubit.recheckPendingSupplierApproval();
      if (!mounted) return;
      final latest = authCubit.state;
      if (latest.status == AuthStatus.authenticated) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.supplierRoute(latest.selectedSupplierRole),
        );
        return;
      }
      ToastUtils.showWarning(context, l10n.tr('auth_pending_still_waiting'));
    } catch (error) {
      if (!mounted) return;
      ToastUtils.showError(context, _localizedErrorMessage(l10n, error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handlePendingLogout() async {
    if (_isSubmitting) return;
    final authCubit = context.read<AuthCubit>();
    setState(() => _isSubmitting = true);

    try {
      _otpTimer?.cancel();
      await authCubit.logout();
      _phoneController.clear();
      _workerPhoneController.clear();
      _passwordController.clear();
      _lastSubmittedOtpCode = '';
      _clearOtpCode();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _localizedErrorMessage(AppLocalizations l10n, Object error) {
    final mapped = ApiService.mapTransportException(error);
    if (mapped.message.startsWith('auth_')) {
      return l10n.tr(mapped.message);
    }
    return mapped.message;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1222),
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status && curr.status == AuthStatus.authenticated,
          listener: (context, state) {
            final route = state.authMode == AuthMode.supplier
                ? AppRoutes.supplierRoute(state.selectedSupplierRole)
                : AppRoutes.workerRoute(state.selectedWorkerRole);

            Navigator.pushNamedAndRemoveUntil(
              context,
              route,
              (route) => false,
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final isSupplierPending =
                          authState.authMode == AuthMode.supplier &&
                          authState.supplierAuthStage ==
                              SupplierAuthStage.pendingApproval;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _LangPill(label: 'FR', locale: Locale('fr')),
                                  _LangPill(label: 'AR', locale: Locale('ar')),
                                  _LangPill(label: 'EN', locale: Locale('en')),
                                  _LangPill(
                                    label: 'BR',
                                    locale: Locale('fr', 'BR'),
                                  ),
                                ],
                              ),
                              if (authState.supplierAuthStage !=
                                      SupplierAuthStage.otp &&
                                  authState.supplierAuthStage !=
                                      SupplierAuthStage.wilaya &&
                                  authState.supplierAuthStage !=
                                      SupplierAuthStage.pendingApproval &&
                                  authState.employeeAuthStep != 2)
                                _AuthModeToggle(
                                  isWorkerMode:
                                      authState.authMode ==
                                      AuthMode.companyWorker,
                                  supplierLabel: l10n.tr('auth_mode_supplier'),
                                  workerLabel: l10n.tr('auth_mode_worker'),
                                  onToggle: () => context
                                      .read<AuthCubit>()
                                      .toggleAuthMode(),
                                ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 24),
                                Center(
                                  child: Image.asset(
                                    'assets/images/full_icon.png',
                                    height: 118,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.diamond_outlined,
                                              size: 100,
                                              color: Colors.orange,
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 48),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 320),
                                  child: isSupplierPending
                                      ? _buildPendingApprovalCard(
                                          l10n,
                                          authState,
                                        )
                                      : _buildAuthFormContent(
                                          l10n: l10n,
                                          isRtl: isRtl,
                                          authState: authState,
                                        ),
                                ),
                                const SizedBox(height: 48),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthFormContent({
    required AppLocalizations l10n,
    required bool isRtl,
    required AuthState authState,
  }) {
    return Column(
      key: const ValueKey('auth-form-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (authState.authMode == AuthMode.supplier &&
            authState.supplierAuthStage == SupplierAuthStage.phone)
          _buildPhoneInput(l10n)
        else if (authState.authMode == AuthMode.supplier &&
            authState.supplierAuthStage == SupplierAuthStage.otp)
          _buildOtpInput(l10n, authState)
        else if (authState.authMode == AuthMode.supplier &&
            authState.supplierAuthStage == SupplierAuthStage.wilaya)
          _buildWilayaDropdown(l10n, authState)
        else if (authState.employeeAuthStep == 1) ...[
          _buildWorkerPhoneInput(l10n),
        ] else ...[
          _buildPasswordInput(l10n),
        ],

        if (authState.authMode == AuthMode.supplier &&
            authState.supplierAuthStage == SupplierAuthStage.phone) ...[
          const SizedBox(height: 32),
          Text(
            l10n.tr('auth_choose_role'),
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSupplierRoles(authState, l10n),
        ],
        const SizedBox(height: 36),
        _buildContinueButton(l10n),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContinueButton(AppLocalizations l10n) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFE27C44), Color(0xFFC75A24)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE27C44).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                l10n.tr('auth_continue'),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildOtpInput(AppLocalizations l10n, AuthState authState) {
    return Column(
      key: const ValueKey('otp-input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tr('auth_otp_hint'),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpControllers.length, (index) {
            return SizedBox(
              width: 44,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF161E31),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange.withOpacity(0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.orange.withOpacity(0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE27C44)),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < _otpFocusNodes.length - 1) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: authState.otpResendSeconds > 0 ? null : _handleResendOtp,
          child: Text(
            authState.otpResendSeconds > 0
                ? l10n
                      .tr('auth_otp_resend_in')
                      .replaceAll('{seconds}', '${authState.otpResendSeconds}')
                : l10n.tr('auth_otp_resend'),
            style: GoogleFonts.inter(
              color: authState.otpResendSeconds > 0
                  ? Colors.white38
                  : const Color(0xFFE27C44),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _handlePendingStatusCheck,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE27C44),
                  side: const BorderSide(color: Color(0xFFE27C44)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE27C44),
                        ),
                      )
                    : Text(
                        l10n.tr('auth_pending_check_status'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: _isSubmitting ? null : _handlePendingLogout,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  l10n.tr('profile_log_out'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingApprovalCard(AppLocalizations l10n, AuthState authState) {
    final signInDate = DateTime.now();
    final deadline = signInDate.add(const Duration(days: 3));
    final deadlineStr =
        '${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year}';
    final signInStr =
        '${signInDate.day.toString().padLeft(2, '0')}/${signInDate.month.toString().padLeft(2, '0')}/${signInDate.year}';

    return Column(
      key: const ValueKey('pending-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.tr('auth_pending_title'),
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          authState.infoMessage ?? l10n.tr('auth_pending_desc'),
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1222),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              _pendingRow(
                icon: Icons.phone_outlined,
                label: authState.phoneNumber.isNotEmpty
                    ? authState.phoneNumber
                    : authState.userEmail ?? '--',
              ),
              const SizedBox(height: 8),
              _pendingRow(
                icon: Icons.location_on_outlined,
                label: authState.wilaya.isNotEmpty ? authState.wilaya : '--',
              ),
              const SizedBox(height: 8),
              _pendingRow(
                icon: Icons.calendar_today_outlined,
                label: l10n
                    .tr('auth_pending_registered_on')
                    .replaceAll('{date}', signInStr),
              ),
              const SizedBox(height: 8),
              _pendingRow(
                icon: Icons.event_available_outlined,
                label: l10n
                    .tr('auth_pending_deadline')
                    .replaceAll('{date}', deadlineStr),
                highlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pendingRow({
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: highlight ? Colors.orange : Colors.white54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: highlight ? Colors.orange : Colors.white70,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWilayaDropdown(AppLocalizations l10n, AuthState authState) {
    const wilayas = [
      '01 - Adrar',
      '02 - Chlef',
      '03 - Laghouat',
      '04 - Oum El Bouaghi',
      '05 - Batna',
      '06 - Béjaïa',
      '07 - Biskra',
      '08 - Béchar',
      '09 - Blida',
      '10 - Bouira',
      '11 - Tamanrasset',
      '12 - Tébessa',
      '13 - Tlemcen',
      '14 - Tiaret',
      '15 - Tizi Ouzou',
      '16 - Alger',
      '17 - Djelfa',
      '18 - Jijel',
      '19 - Sétif',
      '20 - Saïda',
      '21 - Skikda',
      '22 - Sidi Bel Abbès',
      '23 - Annaba',
      '24 - Guelma',
      '25 - Constantine',
      '26 - Médéa',
      '27 - Mostaganem',
      '28 - M\'Sila',
      '29 - Mascara',
      '30 - Ouargla',
      '31 - Oran',
      '32 - El Bayadh',
      '33 - Illizi',
      '34 - Bordj Bou Arréridj',
      '35 - Boumerdès',
      '36 - El Tarf',
      '37 - Tindouf',
      '38 - Tissemsilt',
      '39 - El Oued',
      '40 - Khenchela',
      '41 - Souk Ahras',
      '42 - Tipaza',
      '43 - Mila',
      '44 - Aïn Defla',
      '45 - Naâma',
      '46 - Aïn Témouchent',
      '47 - Ghardaïa',
      '48 - Relizane',
      '49 - Timimoun',
      '50 - Bordj Badji Mokhtar',
      '51 - Ouled Djellal',
      '52 - Béni Abbès',
      '53 - In Salah',
      '54 - In Guezzam',
      '55 - Touggourt',
      '56 - Djanet',
      '57 - El M\'Ghair',
      '58 - El Meniaa',
    ];

    final selectedWilaya = authState.wilaya.isNotEmpty
        ? authState.wilaya
        : null;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161E31),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedWilaya,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2235),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.orange),
          hint: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                l10n.tr('auth_wilaya_hint'),
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
          items: wilayas
              .map(
                (w) => DropdownMenuItem(
                  value: w,
                  child: Text(
                    w,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              context.read<AuthCubit>().updateWilaya(value);
            }
          },
          selectedItemBuilder: (context) => wilayas
              .map(
                (w) => Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPhoneInput(AppLocalizations l10n) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF161E31),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_android,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+213',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 24, color: Colors.white24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.tr('auth_phone_hint'),
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerPhoneInput(AppLocalizations l10n) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF161E31),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_android,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+213',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 24, color: Colors.white24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: const ValueKey('worker-phone-input'),
                  controller: _workerPhoneController,
                  focusNode: _workerPhoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.tr('auth_phone_hint'),
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordInput(AppLocalizations l10n) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF161E31),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 12),
              child: Icon(Icons.lock_outline, color: Colors.white54, size: 24),
            ),
            Container(width: 1, height: 24, color: Colors.white24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: const ValueKey('worker-password-input'),
                  controller: _passwordController,
                  focusNode: _workerPasswordFocusNode,
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.password],
                  enableSuggestions: false,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.tr('auth_password_hint'),
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierRoles(AuthState authState, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _RoleOption(
            title: l10n.tr('auth_role_farmer'),
            iconPath: Icons.pets,
            isSelected: authState.selectedSupplierRole == SupplierRole.farmer,
            onTap: () => context.read<AuthCubit>().selectSupplierRole(
              SupplierRole.farmer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleOption(
            title: l10n.tr('auth_role_producer'),
            iconPath: Icons.factory_outlined,
            isSelected: authState.selectedSupplierRole == SupplierRole.producer,
            onTap: () => context.read<AuthCubit>().selectSupplierRole(
              SupplierRole.producer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleOption(
            title: l10n.tr('auth_role_slaughterhouse'),
            iconPath: Icons.content_cut,
            isSelected:
                authState.selectedSupplierRole == SupplierRole.slaughterhouse,
            onTap: () => context.read<AuthCubit>().selectSupplierRole(
              SupplierRole.slaughterhouse,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  final bool isWorkerMode;
  final String supplierLabel;
  final String workerLabel;
  final VoidCallback onToggle;

  const _AuthModeToggle({
    required this.isWorkerMode,
    required this.supplierLabel,
    required this.workerLabel,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleChip(supplierLabel, !isWorkerMode),
            _toggleChip(workerLabel, isWorkerMode),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDF7E44) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isActive ? Colors.white : Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final Locale locale;

  const _LangPill({required this.label, required this.locale});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<LocaleCubit>().state.locale;
    final isActive = currentLocale == locale;

    return GestureDetector(
      onTap: () => context.read<LocaleCubit>().changeLocale(locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFDF7E44) : const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFDF7E44) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final IconData iconPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDF7E44) : const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFDF7E44) : Colors.white12,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconPath,
              color: isSelected ? Colors.white : Colors.white54,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
