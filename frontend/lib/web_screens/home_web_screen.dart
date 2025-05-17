import 'package:access/web_screens/report_cart.dart';
import 'package:access/web_screens/web_bloc/home_web_bloc/home_web_bloc.dart';
import 'package:access/web_screens/web_bloc/home_web_bloc/home_web_event.dart';
import 'package:access/web_screens/web_bloc/home_web_bloc/home_web_state.dart';
import 'package:access/web_screens/web_bloc/map_bloc/map_event.dart';
import 'package:access/web_screens/web_bloc/map_bloc/map_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'map.dart';

class HomeWebScreen extends StatefulWidget {
  const HomeWebScreen({super.key});

  @override
  _HomeWebScreenState createState() => _HomeWebScreenState();
}

class _HomeWebScreenState extends State<HomeWebScreen> {
  bool hasShownReportDialog = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: Text('This screen is for Web only.')),
      );
    }

    return BlocProvider(
      create: (_) => HomeWebBloc(),
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
                            title: const Text("Προφίλ"),
                            onTap: () {
                              context.read<HomeWebBloc>().add(OpenProfile());
                            },
                          ),
                          ListTile(
                            title: const Text("Προσθήκη βλάβης"),
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
                                      child: SizedBox(
                                        height: 500,
                                        width: 500,
                                        child: ReportCart(
                                          onWorkPeriodReport: () {
                                            Navigator.of(context).pop();
                                          },
                                          onDamageReport: () {
                                            Navigator.of(context).pop();
                                          },
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
                          ListTile(
                            title: const Text("Ρυθμίσεις"),
                            onTap: () {
                              context.read<HomeWebBloc>().add(OpenSettings());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

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
    );

  }
}