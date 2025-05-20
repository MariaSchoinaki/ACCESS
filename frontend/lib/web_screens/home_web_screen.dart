import 'package:access/services/search_service.dart';
import 'package:access/web_screens/profile_screen.dart';
import 'package:access/web_screens/report_card.dart';
import 'package:access/web_screens/web_bloc/home_web_bloc/home_web_bloc.dart';
import 'package:access/web_screens/web_bloc/home_web_bloc/home_web_event.dart';
import 'package:access/web_screens/web_bloc/home_web_bloc/home_web_state.dart';
import 'package:access/web_screens/web_bloc/map_bloc/map_event.dart';
import 'package:access/web_screens/web_bloc/map_bloc/map_bloc.dart';
import 'package:access/web_screens/web_bloc/report_card_bloc/report_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../blocs/search_bloc/search_bloc.dart';

import 'map.dart';

class HomeWebScreen extends StatefulWidget {
  const HomeWebScreen({super.key});

  @override
  _HomeWebScreenState createState() => _HomeWebScreenState();
}

class _HomeWebScreenState extends State<HomeWebScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: Text('This screen is for Web only.')),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => HomeWebBloc()),
        BlocProvider(create: (_) => SearchBloc(searchService: SearchService())),
      ],
      child: BlocListener<SearchBloc, SearchState>(
        listener: (context, state) {
          if (state is SearchLoaded) {
            print('Αποτελέσματα αναζήτησης: ${state.results}');
          } else if (state is SearchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Αποτυχία αναζήτησης')),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text("Accessible City")),
          body: BlocBuilder<HomeWebBloc, HomeWebState>(
            builder: (context, state) {
              return Row(
                children: [
                  // Sidebar
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: IntrinsicWidth(
                      child: Container(
                        color: Colors.grey[200],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Προφίλ'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ProfileScreen()),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.add_box_rounded),
                              title: const Text("Προσθήκη έργου"),
                              onTap: () {
                                if (!state.isReportDialogOpen) {
                                  context.read<HomeWebBloc>().add(OpenReportDialog());
                                  html.document.getElementById('map-iframe')?.style.pointerEvents = 'none';
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: BlocProvider(
                                          create: (_) => ReportBloc(),
                                          child: const SizedBox(
                                            height: 500,
                                            width: 500,
                                            child: ReportCart(),
                                          ),
                                        ),
                                      );
                                    },
                                  ).then((_) {
                                    html.document.getElementById('map-iframe')?.style.pointerEvents = 'auto';
                                    context.read<HomeWebBloc>().add(CloseReportDialog());
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search bar


                  // Map content
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 800,
                        height: 600,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: BlocProvider(
                          create: (_) => MapBloc()..add(const LoadMap()),
                          child: const MapBoxIframeView(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}