import 'dart:ui_web' as ui;
import 'package:access/web_screens/report_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
                child: const MapBoxIframeView(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}