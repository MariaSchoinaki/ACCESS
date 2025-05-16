import 'dart:ui_web' as ui;
import 'package:access/web_screens/report_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

    // Πάρε το token από τη γραμμή εντολών
    const accessToken = String.fromEnvironment('token');

    // Κάνε register το iframe view (μία φορά)
    ui.platformViewRegistry.registerViewFactory('mapbox-view', (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'map.html?token=$accessToken'
        ..id = 'map-iframe'
        ..style.pointerEvents = 'auto' // default
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      return iframe;
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Accessible City")),
      body: Row(
        children: [
          // Sidebar (left)
          Container(
            width: MediaQuery.of(context).size.width * 0.15,
            height: MediaQuery.of(context).size.height,
            color: Colors.grey[200],
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    title: Text("Προφίλ"),
                    onTap: () {
                      print("test");
                    },
                  ),
                  ListTile(
                    title: Text("Προσθήκη βλάβης"),
                    onTap: () {
                      if (!hasShownReportDialog) {
                        setState(() {
                          hasShownReportDialog = true;
                        });
                        html.document.getElementById('map-iframe')?.style.pointerEvents = 'none';

                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                height: 500,
                                width: 500,
                                padding: const EdgeInsets.all(10),
                                child: ReportCart(
                                  onWorkPeriodReport: () {
                                    Navigator.of(context).pop();
                                    print("Αναφορά εργατικής περιόδου");
                                  },
                                  onDamageReport: () {
                                    Navigator.of(context).pop();
                                    print("Αναφορά βλάβης");
                                  },
                                ),
                              ),
                            );
                          },
                        ).then((_) {
                          html.document.getElementById('map-iframe')?.style.pointerEvents = 'auto';
                          setState(() {
                            hasShownReportDialog = false;
                          });
                        });
                      }
                    },

                  ),
                  ListTile(
                    title: Text("Ρυθμίσεις"),
                    onTap: () {
                      print("dsa");
                    },
                  ),
                ],
              ),
            ),
          ),
          // Main content with iframe
          Expanded(
            child: Center(
              child: Container(
                width: 800,
                height: 600,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: const HtmlElementView(viewType: 'mapbox-view'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}