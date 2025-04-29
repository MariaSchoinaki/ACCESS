import 'package:access/screens/login_screen.dart';
import 'package:access/screens/myaccount_screen.dart';
import 'package:access/screens/sign_up_screen.dart';
import 'package:access/services/search_service.dart';
import 'package:access/theme/app_theme.dart' as AppTheme;
import 'package:access/utils/auth_gate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/map_bloc/map_bloc.dart';
import 'blocs/my_account_bloc/my_account_bloc.dart';
import 'blocs/search_bloc/search_bloc.dart';
import 'screens/home_screen.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Entry point of the Flutter application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Securely retrieves the Mapbox access token via --dart-define
  const ACCESS_TOKEN = String.fromEnvironment("token");

  // Validate token and initialize Mapbox
  if (ACCESS_TOKEN.isEmpty) {
    throw Exception('Missing Mapbox access token. Provide it with --dart-define=token=YOUR_TOKEN_HERE');
  }

  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Launch the Flutter application
  runApp(
    BlocProvider(
      create: (_) => MyAccountBloc()..add(LoadUserProfile()),
      child: const MyApp(),
    ),
  );
}

/// Root widget of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Search App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: MultiBlocProvider( // Mobile: Παρέχουμε τους Blocs ΠΑΝΩ από τη HomePage
        providers: [
          BlocProvider(create: (_) => MapBloc()..add(RequestLocationPermission())),
          BlocProvider(create: (_) => SearchBloc(searchService: SearchService())),
          // BlocProvider(create: (_) => MyAccountBloc()..add(LoadUserProfile())),
        ],
        child: const HomePage(),
      ),
      routes: {
        '/home': (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => MapBloc()..add(RequestLocationPermission())),
            BlocProvider(create: (_) => SearchBloc(searchService: SearchService())),
            // Πρόσθεσε κι άλλους Blocs αν τους χρειάζεται η HomePage
          ],
          child: const HomePage(),
        ),
        '/signup': (context) => SignUpPage(),
        '/profile': (context) => AuthGate(),
        '/login': (context) => LoginScreen(),
        '/myaccount': (context) => const MyAccountScreen(),
        '/admin': (context) => const AdminAuthGate(),
      },
    );
  }
}
