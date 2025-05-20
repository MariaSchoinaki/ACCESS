// Flutter constant for checking if platform is Web
import 'package:access/services/search_service.dart';
import 'package:access/web_screens/home_web_screen.dart';
import 'package:access/web_screens/profile_screen.dart';
import 'package:access/web_screens/web_bloc/home_web_bloc/home_web_bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/search_bloc/search_bloc.dart';
import 'firebase_options.dart';


/// Main entry point of the application
Future<void> main() async {
  // Ensure Flutter engine is initialized before any plugin usage
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for all platforms (Android, iOS, Web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run different app depending on platform
  runApp(const WebApp());
}

//
// ==============================================
// WEB VERSION (Browser)
// ==============================================
class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeWebBloc()),
        BlocProvider(create: (_) => SearchBloc(searchService: SearchService())),
      ],
      child: MaterialApp(
        title: 'Accessible City',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),

        initialRoute: '/webhome',
        routes: {
          '/webhome': (context) => const HomeWebScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

