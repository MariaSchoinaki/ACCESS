import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    //if (currentUser == null) {
    //  return const Scaffold(
    //    body: Center(child: Text("Δεν είστε συνδεδεμένος.")),
    //  );
    //}

    // Power BI embed – Web only (iframe inject)
    final powerBiUrl = 'https://app.powerbi.com/view?r=YOUR_PUBLIC_REPORT_ID';
    html.IFrameElement iFrameElement = html.IFrameElement()
      ..src = powerBiUrl
      ..style.border = 'none'
      ..width = '100%'
      ..height = '400';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'power-bi-view',
          (int viewId) => iFrameElement,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Το Προφίλ μου'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Power BI Dashboard',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: HtmlElementView(viewType: 'power-bi-view'),
            ),
            const SizedBox(height: 30),
            const Text(
              'Οι Αναφορές μου',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  //.where('userId', isEqualTo: currentUser.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Δεν υπάρχουν διαθέσιμες αναφορές.');
                }

                final reports = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Card(
                      child: ListTile(
                        title: Text(report['title']),
                        subtitle: Text(
                          'Ημερομηνία: ${report['date'].toDate()}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
