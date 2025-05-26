import 'package:access/services/search_service.dart';
import 'package:access/web_screens/home_web_screen.dart';
import 'package:access/web_screens/profile_screen.dart';
import 'package:access/web_screens/splashscreen.dart';
import 'package:access/web_screens/web_bloc/web_home_bloc/home_web_bloc.dart';
import 'package:access/web_screens/web_bloc/web_signup_bloc/signup_bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'package:access/theme/app_theme.dart' as AppTheme;
// Bloc imports
import 'package:access/web_screens/web_bloc/web_login_screen/login_bloc.dart';
import 'blocs/search_bloc/search_bloc.dart';
import 'package:url_strategy/url_strategy.dart';
// Screens
import 'web_screens/login_screen.dart';
import 'web_screens/signup_screen.dart';

/// Main entry point of the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setPathUrlStrategy();
  runApp(const WebApp());
}

//
// ==============================================
// WEB VERSION
// ==============================================
class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoginBloc()),
        BlocProvider(create: (_) => SignupBloc()),
        BlocProvider(create: (_) => HomeWebBloc()),
        BlocProvider(create: (_) => SearchBloc(searchService: SearchService())),
      ],
      child: MaterialApp(
        title: 'Accessible City',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/webhome': (context) => const HomeWebScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
