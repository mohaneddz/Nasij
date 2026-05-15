import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- State ---
class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState({this.locale = const Locale('fr')});

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }

  @override
  List<Object?> get props => [locale];
}

// --- Cubit ---
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(const LocaleState());

  void changeLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }

  void setFrench() => changeLocale(const Locale('fr'));
  void setArabic() => changeLocale(const Locale('ar'));
  void setEnglish() => changeLocale(const Locale('en'));
  void setBerber() => changeLocale(const Locale('fr', 'BR'));
}
