import 'dart:convert';
import 'package:access/models/metadata.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'opening_hours_utils.dart';

Widget buildMetadataFromList(List<String>? metadataList) {
  if (metadataList == null || metadataList.isEmpty) {
    return const Text('Δεν υπάρχουν διαθέσιμες πληροφορίες.');
  }

  final Map<String, dynamic> metadataMap = _parseMetadata(metadataList);
  final List<Widget> children = [];

  final String? phone = metadataMap['phone'] as String?;
  final String? website = metadataMap['website'] as String?;
  final dynamic openHours = metadataMap['open_hours'];
  print(openHours);

  if (phone != null) {
    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            const Icon(Icons.phone),
            const SizedBox(width: 8.0),
            Text('Τηλέφωνο: $phone'),
          ],
        ),
      ),
    );
  }

  if (website != null) {
    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            const Icon(Icons.web),
            const SizedBox(width: 8.0),
            InkWell(
              onTap: () async {
                print("WEB: " +website);
                final String? trimmedWebsite = website.trim();
                final Uri uri = Uri.parse(trimmedWebsite!);
                if (trimmedWebsite != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  print('Cannot launch URL: $website');
                  // fallback
                }
              },
              child: const Text(
                'Ιστοσελίδα',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(width:8.0),
            const Icon(Icons.open_in_new, size:12),
          ],
        ),
      ),
    );
  }

  if (openHours != null) {
    children.addAll(buildOpeningHoursWidgets(openHours));
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}

Map<String, dynamic> _parseMetadata(List<String> metadataList) {
  final Map<String, dynamic> metadataMap = {};

  for (final item in metadataList) {
    final idx = item.indexOf(':');
    if (idx == -1) continue;
    final key = item.substring(0, idx).trim();
    final value = item.substring(idx + 1).trim();

    if (key == 'open_hours') {
      String openHoursString = value;

      if (value.contains('weekday_text')) {
        String cleanedValue = value.replaceAll(RegExp(r'(\w+):\s*'), '');
        cleanedValue = cleanedValue.replaceAll(RegExp(r'[\[\]\{\}]'), '');
        List<String> weekdayTextList = cleanedValue.split(', ');
        metadataMap[key] = {'weekday_text': [weekdayTextList]};
      } else {
        openHoursString = openHoursString.replaceAllMapped(
            RegExp(r'(\w+):'), (match) => '"${match.group(1)}":');
        openHoursString = openHoursString.replaceAllMapped(
            RegExp(r'([{,]\s*)(\w+):'), (match) => '${match.group(1)}"${match.group(2)}":');
        openHoursString = openHoursString.replaceAllMapped(
            RegExp(r'("time"\s*:\s*)(\d{4})'), (match) => '${match.group(1)}"${match.group(2)}"');

        print(openHoursString);
        try {
          metadataMap[key] = jsonDecode(openHoursString);
        } catch (_) {
          metadataMap[key] = null;
          print('Σφάλμα κατά την ανάλυση JSON: $value');
        }
      }
    } else {
      metadataMap[key] = value;
    }
  }

  return metadataMap;
}

ParsedMetadata createMetaData(List<String> metadataList) {

  final Map<String, dynamic> metadataMap = _parseMetadata(metadataList);
  ParsedMetadata? metaData = ParsedMetadata();
  metaData.phone = metadataMap['phone'] as String?;
  metaData.website = metadataMap['website'] as String?;
  return metaData;
}
