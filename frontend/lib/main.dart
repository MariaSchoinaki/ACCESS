import 'package:access/screens/login_screen.dart';
import 'package:access/screens/myaccount_screen.dart';
import 'package:access/screens/sign_up_screen.dart';
import 'package:access/services/search_service.dart';
import 'package:access/theme/app_theme.dart' as AppTheme;
import 'package:access/utils/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/map_bloc/map_bloc.dart';
import 'blocs/my_account_bloc/my_account_bloc.dart';
import 'blocs/search_bloc/search_bloc.dart';
import 'screens/home_screen.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Main entry point for the application
///
/// Initializes:
/// - Flutter framework bindings
/// - Mapbox SDK with access token
/// - Firebase services
///
/// Throws:
/// - [Exception] if Mapbox access token is not provided
///
/// Usage:
/// ```bash
/// flutter run --dart-define=token=YOUR_MAPBOX_TOKEN
/// ```
Future<void> main() async {
  // Initialize Flutter framework bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Securely retrieve Mapbox access token from build arguments
  const ACCESS_TOKEN = String.fromEnvironment("token");

  // Validate and set Mapbox configuration
  if (ACCESS_TOKEN.isEmpty) {
    throw Exception('Missing Mapbox access token. Provide it with --dart-define=token=YOUR_TOKEN_HERE');
  }
  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  // Initialize Firebase services
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Launch the application with BLoC provider
  runApp(
    MultiBlocProvider(
      providers: [
        // Ο MyAccountBloc που είχες ήδη
        BlocProvider<MyAccountBloc>(
          create: (_) => MyAccountBloc()..add(LoadUserProfile()),
        ),
        // Πρόσθεσε τον MapBloc εδώ
        BlocProvider<MapBloc>(
          // RequestLocationPermission ίσως καλύτερα να καλείται από το HomePage initState;
          // Αλλιώς, το ..add() εδώ θα το τρέξει κατά την αρχικοποίηση.
          create: (_) => MapBloc()..add(RequestLocationPermission()),
        ),
        // Πρόσθεσε τον SearchBloc εδώ
        BlocProvider<SearchBloc>(
          create: (_) => SearchBloc(searchService: SearchService()),
        ),
        // Πρόσθεσε κι άλλους Blocs εδώ αν χρειάζεται
      ],
      child: const MyApp(),
    ),
  );
}

/// Root application widget configuring global settings
///
/// Features:
/// - Theme management (light/dark modes)
/// - Route configuration
/// - BLoC provider integration
/// - Authentication flow
///
/// Routes:
/// - '/home' : Main application screen
/// - '/signup' : User registration
/// - '/profile' : Authentication gateway
/// - '/login' : User login
/// - '/myaccount' : User profile management
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Builds the root application structure
  ///
  /// Returns:
  /// [MaterialApp] configured with:
  /// - Theme settings from AppTheme
  /// - Named route navigation
  /// - BLoC providers for state management
  /// - Authentication flow integration
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapbox Search App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/signup': (context) => SignUpPage(),
        '/profile': (context) => AuthGate(),
        '/login': (context) => LoginScreen(),
        '/myaccount': (context) => const MyAccountScreen(),
      },
    );
  }
}