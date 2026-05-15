import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/connectivity_cubit.dart';
import 'cubits/locale_cubit.dart';
import 'cubits/sync_cubit.dart';
import 'data/offline_storage.dart';
import 'l10n/app_localizations.dart';
import 'routes/app_routes.dart';
import 'routes/app_router.dart';
import 'services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var envLoaded = false;
  for (final fileName in const ['assets/env', 'assets/.env']) {
    try {
      await dotenv.load(fileName: fileName);
      envLoaded = true;
      break;
    } catch (_) {
      // Try next supported env path.
    }
  }
  if (!envLoaded) {
    // Keep runtime defaults when no env file is available.
  }

  // Initialize Hive offline storage
  final offlineStorage = OfflineStorage();
  await offlineStorage.init();
  await BackgroundSyncService.initialize();
  await BackgroundSyncService.schedulePeriodicSync();

  runApp(NasijApp(offlineStorage: offlineStorage));
}

class NasijApp extends StatelessWidget {
  final OfflineStorage offlineStorage;

  const NasijApp({super.key, required this.offlineStorage});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(storage: offlineStorage),
        ),
        BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()),
        BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
        BlocProvider<SyncCubit>(
          create: (ctx) => SyncCubit(
            storage: offlineStorage,
            connectivityCubit: ctx.read<ConnectivityCubit>(),
          ),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp(
            title: 'Nassaj',
            debugShowCheckedModeBanner: false,
            locale: localeState.locale,
            supportedLocales: const [
              Locale('fr'),
              Locale('ar'),
              Locale('en'),
              Locale('fr', 'BR'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
