import 'dart:async';
import 'package:access/services/search_service.dart';
import 'package:access/web_screens/report_card.dart';
import 'package:access/web_screens/web_bloc/web_home_bloc/home_web_bloc.dart';
import 'package:access/web_screens/web_bloc/web_map_bloc/map_bloc.dart';
import 'package:access/web_screens/web_bloc/web_report_card_bloc/report_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../blocs/search_bloc/search_bloc.dart';
import 'package:access/theme/app_colors.dart';
import 'map.dart';

class HomeWebScreen extends StatefulWidget {
  const HomeWebScreen({super.key});

  @override
  _HomeWebScreenState createState() => _HomeWebScreenState();
}

class _HomeWebScreenState extends State<HomeWebScreen> {
  StreamSubscription<html.PopStateEvent>? _popStateSubscription;
  List<dynamic> clusters = [];
  bool _isMapLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadClusters();
    final authToken = html.window.localStorage['authToken'];
    if (authToken == null) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
    } else {
      _popStateSubscription = html.window.onPopState.listen((event) {
        if (ModalRoute.of(context)?.settings.name == '/webhome') {
          return;
        }
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }

    html.window.onMessage.listen((event) {
      try {
        if (event.data['type'] == 'mapLongPress') {
          final coords = List<double>.from(event.data['coordinates']);
          _handleLongPress(coords);
        }
        else if (event.data['type'] == 'mapLoaded') {
          setState(() {
            _isMapLoaded = true;
          });
          if (clusters.isNotEmpty) {
            _sendClustersToMap();
          }
        }
        else if (event.data['type'] == 'clusterMarkerClick') {
          _showClusterReports(event.data['reports']);
        }
      } catch (e) {
        print('Error handling map event: $e');
      }
    });
  }

  Future<void> _loadClusters() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:9090/setreport'));
      if (response.statusCode == 200) {
        setState(() {
          clusters = json.decode(response.body);
        });

        if (_isMapLoaded) {
          _sendClustersToMap();
        }
      }
    } catch (e) {
      print('Σφάλμα φόρτωσης clusters: $e');
    }
  }

  void _sendClustersToMap() {
    final iframe = html.document.getElementById('map-iframe') as html.IFrameElement?;
    if (iframe?.contentWindow != null) {
      iframe!.contentWindow!.postMessage({
        'type': 'addClusterMarkers',
        'clusters': clusters,
      }, '*');
    }
  }

  void _showClusterReports(List<dynamic> reports) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Αναφορές (${reports.length})'),
        content: SizedBox(
          width: 500,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ListTile(
                title: Text(report['locationDescription']),
                subtitle: Text('${report['timestamp']}\nΣυντεταγμένες: ${report['latitude']}, ${report['longitude']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Κλείσιμο'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _popStateSubscription?.cancel();
    super.dispose();
  }

  void _handleLongPress(List<double> coordinates) {
    html.document.getElementById('map-iframe')?.style.pointerEvents = 'none';
    if (!context.read<HomeWebBloc>().state.isReportDialogOpen) {
      context.read<HomeWebBloc>().add(OpenReportDialog());
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: BlocProvider.of<SearchBloc>(context)),
                BlocProvider(create: (_) => ReportBloc()),
              ],
              child: SizedBox(
                height: 500,
                width: 500,
                child: ReportCard(coordinates: coordinates),
              ),
            ),
          );
        },
      ).then((_) {
        html.document.getElementById('map-iframe')?.style.pointerEvents = 'auto';
        context.read<HomeWebBloc>().add(CloseReportDialog());
        _loadClusters();
      });
    }
  }

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
          appBar: AppBar(
            title: const Text("Accessible City"),
            automaticallyImplyLeading: false,
          ),
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
                        decoration: BoxDecoration(
                          color: AppColors.creamAccent[100],
                          border: Border.all(color: AppColors.cream, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Προφίλ'),
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.add_box_rounded),
                              title: const Text("Προσθήκη έργου"),
                              onTap: () {
                                if (!state.isReportDialogOpen) {
                                  context.read<HomeWebBloc>().add(
                                    OpenReportDialog(),
                                  );
                                  html.document.getElementById('map-iframe')?.style.pointerEvents = 'none';
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: BlocProvider(
                                          create: (_) => ReportBloc(),
                                          child: const SizedBox(
                                            height: 500,
                                            width: 500,
                                            child: ReportCard(),
                                          ),
                                        ),
                                      );
                                    },
                                  ).then((_) {
                                    html.document.getElementById('map-iframe')?.style.pointerEvents = 'auto';
                                    context.read<HomeWebBloc>().add(CloseReportDialog());
                                    _loadClusters();
                                  });
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.exit_to_app),
                              title: const Text('Αποσύνδεση'),
                              onTap: () {
                                html.window.localStorage.remove('authToken');
                                html.window.history.replaceState(null, '', '/login');
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                          color: AppColors.white,
                          border: Border.all(color: AppColors.secondary),
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