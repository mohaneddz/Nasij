import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/offline_storage.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, authenticated, pendingApproval, unauthenticated }

enum AuthMode { supplier, companyWorker }

enum SupplierRole { farmer, producer, slaughterhouse }

enum WorkerRole { collector, depot, lavery, transformation }

enum SupplierAuthStage { phone, wilaya, otp, pendingApproval }

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthMode authMode;
  final SupplierRole selectedSupplierRole;
  final WorkerRole selectedWorkerRole;
  final SupplierAuthStage supplierAuthStage;
  final int otpResendSeconds;
  final String phoneNumber;
  final String workerPhone;
  final String workerPassword;
  final int employeeAuthStep;
  final String? userId;
  final String? accessToken;
  final String? refreshToken;
  final int trustScore;
  final String? approvalStatus;
  final String? userName;
  final String? userEmail;
  final String? infoMessage;
  final String wilaya;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.authMode = AuthMode.supplier,
    this.selectedSupplierRole = SupplierRole.farmer,
    this.selectedWorkerRole = WorkerRole.collector,
    this.supplierAuthStage = SupplierAuthStage.phone,
    this.otpResendSeconds = 0,
    this.phoneNumber = '',
    this.workerPhone = '',
    this.workerPassword = '',
    this.employeeAuthStep = 1,
    this.userId,
    this.accessToken,
    this.refreshToken,
    this.trustScore = 100,
    this.approvalStatus,
    this.userName,
    this.userEmail,
    this.infoMessage,
    this.wilaya = '',
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthMode? authMode,
    SupplierRole? selectedSupplierRole,
    WorkerRole? selectedWorkerRole,
    SupplierAuthStage? supplierAuthStage,
    int? otpResendSeconds,
    String? phoneNumber,
    String? workerPhone,
    String? workerPassword,
    int? employeeAuthStep,
    String? userId,
    String? accessToken,
    String? refreshToken,
    int? trustScore,
    String? approvalStatus,
    String? userName,
    String? userEmail,
    String? infoMessage,
    String? wilaya,
  }) {
    return AuthState(
      status: status ?? this.status,
      authMode: authMode ?? this.authMode,
      selectedSupplierRole: selectedSupplierRole ?? this.selectedSupplierRole,
      selectedWorkerRole: selectedWorkerRole ?? this.selectedWorkerRole,
      supplierAuthStage: supplierAuthStage ?? this.supplierAuthStage,
      otpResendSeconds: otpResendSeconds ?? this.otpResendSeconds,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      workerPhone: workerPhone ?? this.workerPhone,
      workerPassword: workerPassword ?? this.workerPassword,
      employeeAuthStep: employeeAuthStep ?? this.employeeAuthStep,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      trustScore: trustScore ?? this.trustScore,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      infoMessage: infoMessage ?? this.infoMessage,
      wilaya: wilaya ?? this.wilaya,
    );
  }

  @override
  List<Object?> get props => [
    status,
    authMode,
    selectedSupplierRole,
    selectedWorkerRole,
    supplierAuthStage,
    otpResendSeconds,
    phoneNumber,
    workerPhone,
    workerPassword,
    employeeAuthStep,
    userId,
    accessToken,
    refreshToken,
    trustScore,
    approvalStatus,
    userName,
    userEmail,
    infoMessage,
    wilaya,
  ];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({OfflineStorage? storage})
    : _storage = storage ?? OfflineStorage(),
      super(const AuthState(status: AuthStatus.initial));

  final OfflineStorage _storage;

  void toggleAuthMode() {
    final newMode = state.authMode == AuthMode.supplier
        ? AuthMode.companyWorker
        : AuthMode.supplier;
    emit(
      state.copyWith(
        authMode: newMode,
        employeeAuthStep: 1,
        supplierAuthStage: SupplierAuthStage.phone,
        otpResendSeconds: 0,
        infoMessage: null,
      ),
    );
  }

  void setAuthMode(AuthMode mode) {
    emit(state.copyWith(authMode: mode));
  }

  void selectSupplierRole(SupplierRole role) {
    emit(state.copyWith(selectedSupplierRole: role));
  }

  void selectWorkerRole(WorkerRole role) {
    emit(state.copyWith(selectedWorkerRole: role));
  }

  void updatePhoneNumber(String phone) {
    emit(state.copyWith(phoneNumber: phone));
  }

  void updateWilaya(String wilaya) {
    emit(state.copyWith(wilaya: wilaya));
  }

  void advanceToWilayaStage() {
    emit(state.copyWith(supplierAuthStage: SupplierAuthStage.wilaya));
  }

  void advanceToOtpStage() {
    emit(state.copyWith(supplierAuthStage: SupplierAuthStage.otp));
  }

  void updateWorkerPhone(String phone) {
    emit(state.copyWith(workerPhone: phone));
  }

  void updateWorkerPassword(String password) {
    emit(state.copyWith(workerPassword: password));
  }

  void nextAuthStep() {
    if (state.employeeAuthStep == 1) {
      emit(state.copyWith(employeeAuthStep: 2));
    }
  }

  void prevAuthStep() {
    if (state.employeeAuthStep == 2) {
      emit(state.copyWith(employeeAuthStep: 1));
    }
  }

  void setOtpResendSeconds(int seconds) {
    emit(state.copyWith(otpResendSeconds: seconds));
  }

  void tickOtpResendSeconds() {
    if (state.otpResendSeconds <= 0) return;
    emit(state.copyWith(otpResendSeconds: state.otpResendSeconds - 1));
  }

  void resetSupplierAuthFlow() {
    emit(
      state.copyWith(
        supplierAuthStage: SupplierAuthStage.phone,
        otpResendSeconds: 0,
        infoMessage: null,
      ),
    );
  }

  String? validatePhone() {
    final phone = state.phoneNumber.trim();

    if (phone.isEmpty) {
      return 'auth_error_empty_phone';
    }

    final phoneRegExp = RegExp(r'^(05|06|07)[0-9]{8}$');
    if (!phoneRegExp.hasMatch(phone)) {
      return 'auth_error_invalid_phone';
    }

    return null;
  }

  String? validateWorkerPhone() {
    final phone = state.workerPhone.trim();

    if (phone.isEmpty) {
      return 'auth_error_empty_phone';
    }

    final phoneRegExp = RegExp(r'^(05|06|07)[0-9]{8}$');
    if (!phoneRegExp.hasMatch(phone)) {
      return 'auth_error_invalid_phone';
    }

    return null;
  }

  String? validatePassword() {
    if (state.workerPassword.isEmpty) {
      return 'auth_error_empty_password';
    }

    final password = state.workerPassword.trim();
    final numericOnly = RegExp(r'^\d+$');
    if (numericOnly.hasMatch(password)) {
      return 'auth_error_password_not_numeric';
    }

    return null;
  }

  Future<void> requestSupplierOtp() async {
    await ApiService.requestSupplierOtp(
      phone: state.phoneNumber.trim(),
      supplierRole: state.selectedSupplierRole,
      fullName: state.userName,
      wilaya: state.wilaya,
    );
    emit(
      state.copyWith(
        supplierAuthStage: SupplierAuthStage.otp,
        otpResendSeconds: 60,
        infoMessage: null,
      ),
    );
  }

  Future<void> verifySupplierOtp(
    String otpCode, {
    bool requireWilayaForPending = false,
  }) async {
    final response = await ApiService.verifySupplierOtp(
      phone: state.phoneNumber.trim(),
      supplierRole: state.selectedSupplierRole,
      otpCode: otpCode,
      fullName: state.userName,
      wilaya: state.wilaya,
    );

    final approvalStatus =
        (response['approval_status'] as String?) ?? 'PENDING_APPROVAL';
    final trustScore = response['trust_score'] as int? ?? 100;
    final userName = response['full_name'] as String?;
    final userPhone = response['phone'] as String? ?? state.phoneNumber.trim();
    final responseWilaya = (response['wilaya'] as String? ?? '').trim();
    final effectiveWilaya = state.wilaya.trim().isNotEmpty
        ? state.wilaya.trim()
        : responseWilaya;

    if (approvalStatus != 'APPROVED') {
      if (requireWilayaForPending && effectiveWilaya.isEmpty) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            supplierAuthStage: SupplierAuthStage.wilaya,
            approvalStatus: approvalStatus,
            trustScore: trustScore,
            userName: userName,
            userEmail: userPhone,
            infoMessage: response['message'] as String?,
            wilaya: effectiveWilaya,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.pendingApproval,
          supplierAuthStage: SupplierAuthStage.pendingApproval,
          approvalStatus: approvalStatus,
          trustScore: trustScore,
          userName: userName,
          userEmail: userPhone,
          infoMessage: response['message'] as String?,
          wilaya: effectiveWilaya,
        ),
      );
      await _storage.saveSession({
        'status': AuthStatus.pendingApproval.name,
        'authMode': AuthMode.supplier.name,
        'selectedSupplierRole': state.selectedSupplierRole.name,
        'selectedWorkerRole': state.selectedWorkerRole.name,
        'supplierAuthStage': SupplierAuthStage.pendingApproval.name,
        'otpResendSeconds': 0,
        'phoneNumber': userPhone,
        'trustScore': trustScore,
        'approvalStatus': approvalStatus,
        'userName': userName,
        'userEmail': userPhone,
        'wilaya': effectiveWilaya,
      });
      return;
    }

    final nextState = state.copyWith(
      status: AuthStatus.authenticated,
      supplierAuthStage: SupplierAuthStage.phone,
      otpResendSeconds: 0,
      userId: response['user_id'] as String?,
      accessToken: response['access_token'] as String?,
      refreshToken: response['refresh_token'] as String?,
      trustScore: trustScore,
      approvalStatus: approvalStatus,
      userName: userName,
      userEmail: userPhone,
      infoMessage: null,
      wilaya: effectiveWilaya,
    );
    emit(nextState);

    await _storage.saveSession({
      'status': AuthStatus.authenticated.name,
      'authMode': nextState.authMode.name,
      'selectedSupplierRole': nextState.selectedSupplierRole.name,
      'selectedWorkerRole': nextState.selectedWorkerRole.name,
      'supplierAuthStage': SupplierAuthStage.phone.name,
      'otpResendSeconds': 0,
      'phoneNumber': userPhone,
      'workerPhone': nextState.workerPhone,
      'workerEmail': nextState.workerPhone,
      'userId': nextState.userId,
      'accessToken': nextState.accessToken,
      'refreshToken': nextState.refreshToken,
      'trustScore': nextState.trustScore,
      'approvalStatus': nextState.approvalStatus,
      'userName': nextState.userName,
      'userEmail': nextState.userEmail,
      'wilaya': nextState.wilaya,
    });
  }

  Future<void> recheckPendingSupplierApproval() async {
    if (state.authMode != AuthMode.supplier) return;
    if (state.phoneNumber.trim().isEmpty) return;
    await verifySupplierOtp('000000');
  }

  Future<void> refreshSupplierProfile() async {
    if (state.accessToken == null || state.accessToken!.isEmpty) return;
    final profile = await ApiService.getSupplierProfile(
      accessToken: state.accessToken!,
    );

    final currentSession = _storage.getSession() ?? {};
    final latestAccessToken =
        currentSession['accessToken'] as String? ?? state.accessToken;
    final latestRefreshToken =
        currentSession['refreshToken'] as String? ?? state.refreshToken;

    emit(
      state.copyWith(
        accessToken: latestAccessToken,
        refreshToken: latestRefreshToken,
        trustScore: profile['trust_score'] as int? ?? state.trustScore,
        userName: profile['full_name'] as String? ?? state.userName,
        userEmail: profile['phone'] as String? ?? state.userEmail,
        approvalStatus:
            profile['approval_status'] as String? ?? state.approvalStatus,
      ),
    );
    await _storage.saveSession({
      'status': state.status.name,
      'authMode': state.authMode.name,
      'selectedSupplierRole': state.selectedSupplierRole.name,
      'selectedWorkerRole': state.selectedWorkerRole.name,
      'supplierAuthStage': state.supplierAuthStage.name,
      'otpResendSeconds': state.otpResendSeconds,
      'phoneNumber': state.phoneNumber,
      'workerPhone': state.workerPhone,
      'workerEmail': state.workerPhone,
      'userId': state.userId,
      'accessToken': latestAccessToken,
      'refreshToken': latestRefreshToken,
      'trustScore': profile['trust_score'] as int? ?? state.trustScore,
      'approvalStatus':
          profile['approval_status'] as String? ?? state.approvalStatus,
      'userName': profile['full_name'] as String? ?? state.userName,
      'userEmail': profile['phone'] as String? ?? state.userEmail,
    });
  }

  Future<void> restoreSession() async {
    final sessionData = _storage.getSession();

    if (sessionData == null) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }

    try {
      final restoredState = AuthState(
        status: AuthStatus.values.byName(
          sessionData['status'] as String? ?? AuthStatus.unauthenticated.name,
        ),
        authMode: AuthMode.values.byName(
          sessionData['authMode'] as String? ?? AuthMode.supplier.name,
        ),
        selectedSupplierRole: SupplierRole.values.byName(
          sessionData['selectedSupplierRole'] as String? ??
              SupplierRole.farmer.name,
        ),
        selectedWorkerRole: WorkerRole.values.byName(
          sessionData['selectedWorkerRole'] as String? ??
              WorkerRole.collector.name,
        ),
        supplierAuthStage: SupplierAuthStage.values.byName(
          sessionData['supplierAuthStage'] as String? ??
              SupplierAuthStage.phone.name,
        ),
        wilaya: sessionData['wilaya'] as String? ?? '',
        otpResendSeconds: sessionData['otpResendSeconds'] as int? ?? 0,
        phoneNumber: sessionData['phoneNumber'] as String? ?? '',
        workerPhone:
            sessionData['workerPhone'] as String? ??
            sessionData['workerEmail'] as String? ??
            '',
        employeeAuthStep: 1,
        userId: sessionData['userId'] as String?,
        accessToken: sessionData['accessToken'] as String?,
        refreshToken: sessionData['refreshToken'] as String?,
        trustScore: sessionData['trustScore'] as int? ?? 100,
        approvalStatus: sessionData['approvalStatus'] as String?,
        userName: sessionData['userName'] as String?,
        userEmail: sessionData['userEmail'] as String?,
        infoMessage: sessionData['infoMessage'] as String?,
      );

      if (restoredState.status == AuthStatus.pendingApproval) {
        emit(
          restoredState.copyWith(
            authMode: AuthMode.supplier,
            supplierAuthStage: SupplierAuthStage.pendingApproval,
            otpResendSeconds: 0,
            employeeAuthStep: 1,
          ),
        );
        try {
          await recheckPendingSupplierApproval();
        } catch (_) {
          // Keep pending state when offline/server unreachable.
        }
        return;
      }

      emit(restoredState);
    } catch (_) {
      await _storage.clearSession();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  WorkerRole _sectorToWorkerRole(String? sector) {
    switch ((sector ?? '').toUpperCase()) {
      case 'DEPOT_WORKER':
        return WorkerRole.depot;
      case 'LAVAGE_WORKER':
        return WorkerRole.lavery;
      case 'TRANSFORMATEUR':
        return WorkerRole.transformation;
      // Collector can be stored as various sector values
      case 'C1_COLLECTOR':
      case 'C1_FARMER':
      case 'COLLECTEUR':
      case 'COLLECTOR':
      default:
        return WorkerRole.collector;
    }
  }

  Future<void> login() async {
    final response = await ApiService.employeeLogin(
      phone: state.workerPhone.trim(),
      password: state.workerPassword,
    );

    final detectedRole = _sectorToWorkerRole(response['sector'] as String?);
    final nextState = state.copyWith(
      status: AuthStatus.authenticated,
      selectedWorkerRole: detectedRole,
      userId: response['user_id'] as String?,
      accessToken: response['access_token'] as String?,
      refreshToken: response['refresh_token'] as String?,
      userName: response['full_name'] as String?,
      userEmail: response['phone'] as String? ?? state.workerPhone.trim(),
    );

    emit(nextState);

    await _storage.saveSession({
      'status': AuthStatus.authenticated.name,
      'authMode': nextState.authMode.name,
      'selectedSupplierRole': nextState.selectedSupplierRole.name,
      'selectedWorkerRole': detectedRole.name,
      'supplierAuthStage': SupplierAuthStage.phone.name,
      'otpResendSeconds': 0,
      'phoneNumber': nextState.phoneNumber,
      'workerPhone': nextState.workerPhone,
      'workerEmail': nextState.workerPhone,
      'userId': nextState.userId,
      'accessToken': nextState.accessToken,
      'refreshToken': nextState.refreshToken,
      'trustScore': nextState.trustScore,
      'approvalStatus': nextState.approvalStatus,
      'userName': nextState.userName,
      'userEmail': nextState.userEmail,
    });
  }

  Future<void> logout() async {
    await _storage.clearSession();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
