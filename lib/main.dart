import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'config/routes/app_router.dart';
import 'shared/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Easy Localization
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('th'), Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: FruitFactoryApp(),
      ),
    ),
  );
}

class FruitFactoryApp extends ConsumerWidget {
  const FruitFactoryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844), // Mobile design baseline
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Fruit Factory Stock',
          theme: ThemeData(
            primarySwatch: Colors.green,
            useMaterial3: true,
            fontFamily: 'NotoSansThai',
          ),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            EasyLocalization.of(context)?.delegate ?? const _FallbackDelegate(),
          ],
          supportedLocales: EasyLocalization.of(context)?.supportedLocales ?? 
              const [Locale('en'), Locale('th')],
          locale: context.locale,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class _FallbackDelegate extends LocalizationsDelegate<void> {
  const _FallbackDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<void> load(Locale locale) async => null;

  @override
  bool shouldReload(LocalizationsDelegate<void> old) => false;
}
