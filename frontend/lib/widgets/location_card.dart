import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../models/mapbox_feature.dart';
import '../services/map_service.dart';

/// Card widget to display location info and fetch/display route(s).
class LocationInfoCard extends StatelessWidget {
  final MapboxFeature? feature;
  final MapboxFeature? feature2;

  const LocationInfoCard({Key? key, required this.feature, this.feature2}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (feature == null) return const SizedBox.shrink();
    print(feature2?.metadata);

    print(feature2);
    print(feature == feature2);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            feature?.name ?? 'Άγνωστη Τοποθεσία',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            feature?.fullAddress ?? 'Δεν βρέθηκε διεύθυνση',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          if (feature?.poiCategory != null &&
              feature!.poiCategory.isNotEmpty &&
              !(feature!.poiCategory.length == 1 &&
                  feature!.poiCategory.first == 'address'))
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Κατηγορίες: ${feature!.poiCategory.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.hintColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Προσβασιμότητα: ', style: theme.textTheme.bodyMedium),
              Icon(
                feature?.accessibleFriendly ?? false
                    ? Icons.accessible_forward
                    : Icons.not_accessible,
                color: feature?.accessibleFriendly ?? false
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                feature?.accessibleFriendly ?? false
                    ? 'Προσβάσιμο'
                    : 'Μη Προσβάσιμο',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: feature?.accessibleFriendly ?? false
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${feature?.latitude?.toStringAsFixed(5) ?? 'N/A'}   Lon: ${feature?.longitude?.toStringAsFixed(5) ?? 'N/A'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _fetchAndDisplayRoute(context, alternatives: false),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Έναρξη'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _fetchAndDisplayRoute(context, alternatives: true),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Οδηγίες'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => context.read<MapBloc>().add(ShareLocationRequested(feature!.id)),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Κλήση'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => context.read<MapBloc>().add(ShareLocationRequested(feature!.id)),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Μοίρασε'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          buildMetadataFromList(feature2?.metadata),
        ],
      ),
    );
  }

  Future<void> _shareLocation(String locationId) async {
    String url = 'https://accessiblecity.gr/location?id=$locationId';
    await Share.share('Δείτε αυτή την τοποθεσία: $url');
  }

  void _launchPhoneDialer(String phoneNumber) async {
    if (await canLaunchUrlString(phoneNumber)) {
      await launchUrlString(phoneNumber);
    } else {
      // Show an error message if the phone app can't be launched
      print('Could not launch $phoneNumber');
    }
  }


  Widget buildMetadataFromList(List<String>? metadataList) {
    if (metadataList == null || metadataList.isEmpty) {
      print(metadataList);
      return const Text('FUCK');
    }

    Map<String, dynamic> metadataMap = {};
    for (final item in metadataList) {
      int idx = item.indexOf(":");
      final parts = [item.substring(0,idx).trim(), item.substring(idx+1).trim()];
      print(parts);
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        if (key == 'open_hours') {
          String openHoursString = value;
          print('Attempting to decode (raw): "$openHoursString"');

          // Attempt to add quotes around top-level keys
          openHoursString = openHoursString.replaceAllMapped(RegExp(r'(\w+):'), (match) => '"${match.group(1)}":');

          // Specifically target keys 'open' and 'close' within objects
          openHoursString = openHoursString.replaceAllMapped(RegExp(r'([{,]\s*)(\w+):'), (match) => '${match.group(1)}"${match.group(2)}":');

          // Specifically target the 'time' values to enclose them in quotes
          openHoursString = openHoursString.replaceAllMapped(RegExp(r'("time"\s*:\s*)(\d{4})'), (match) => '${match.group(1)}"${match.group(2)}"');

          print('Attempting to decode (fixed): "$openHoursString"');

          try {
            metadataMap[key] = jsonDecode(openHoursString);
          } catch (e) {
            print('Error decoding open_hours after manual fix (attempt 3): $e');
          }
        } else {
          metadataMap[key] = value;
        }
      }
    }

    final String? phone = metadataMap['phone'] as String?;
    final String? website = metadataMap['website'] as String?;
    final List<dynamic>? periods = metadataMap['open_hours']?['periods'] as List<dynamic>?;
    print(periods);

    List<Widget> children = [];

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
    for(int i = 0; i < feature2!.metadata.length!; i++){
      print(feature2?.metadata[i]);
    }
    if (website != null) {
      print(website);
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              const Icon(Icons.web),
              const SizedBox(width: 8.0),
              InkWell(
                onTap: () async {
                  final Uri uri = Uri.parse(website);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(primaryFocus!.context!).showSnackBar(
                      const SnackBar(content: Text('Δεν ήταν δυνατό να ανοιχτεί ο σύνδεσμος.')),
                    );
                  }
                },
                child: const Text(
                  'Ιστοσελίδα',
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (periods != null && periods.isNotEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Ώρες Λειτουργίας:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      for (final period in periods) {
        final open = period['open'] as Map<String, dynamic>?;
        final close = period['close'] as Map<String, dynamic>?;

        final int? openDay = open?['day'] as int?;
        final String? openTime = open?['time'] as String?;
        final int? closeDay = close?['day'] as int?;
        final String? closeTime = close?['time'] as String?;

        String? formattedOpenTime;
        if (openTime != null && openTime.length == 4) {
          final hour = int.parse(openTime.substring(0, 2));
          final minute = openTime.substring(2, 4);
          final periodAmPm = hour < 12 ? 'πμ' : 'μμ';
          final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
          formattedOpenTime = '$formattedHour:$minute $periodAmPm';
        }

        String? formattedCloseTime;
        if (closeTime != null && closeTime.length == 4) {
          final hour = int.parse(closeTime.substring(0, 2));
          final minute = closeTime.substring(2, 4);
          final periodAmPm = hour < 12 ? 'πμ' : 'μμ';
          final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
          formattedCloseTime = '$formattedHour:$minute $periodAmPm';
        }

        String? openDayStr;
        if (openDay != null) {
          openDayStr = ['Κυριακή', 'Δευτέρα', 'Τρίτη', 'Τετάρτη', 'Πέμπτη', 'Παρασκευή', 'Σάββατο'][openDay];
        }

        String? closeDayStr;
        if (closeDay != null) {
          closeDayStr = ['Κυριακή', 'Δευτέρα', 'Τρίτη', 'Τετάρτη', 'Πέμπτη', 'Παρασκευή', 'Σάββατο'][closeDay];
        }

        String periodText = '';
        if (openDayStr == closeDayStr) {
          periodText = '$openDayStr: $formattedOpenTime - $formattedCloseTime';
        } else {
          periodText = '$openDayStr $formattedOpenTime - $closeDayStr $formattedCloseTime';
        }

        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(periodText.isNotEmpty ? periodText : 'Άγνωστες ώρες'),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Fetches and displays route(s) using MapService and dispatches events to MapBloc.
  void _fetchAndDisplayRoute(BuildContext context, {required bool alternatives}) async {
    if (feature == null) {
      print("Attempted to navigate but feature was null.");
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      final mapService = MapService();

      // Call the API with `alternatives` query param
      final responseJson = await mapService.getRoutesJson(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: feature!.latitude,
        toLng: feature!.longitude,
        alternatives: alternatives,
      );

      if (alternatives) {
        // Extract all routes
        final List<List<List<double>>> alternativeRoutes = [];

        final routes = responseJson['routes'] as List<dynamic>?;


        if (routes != null) {
          for (var route in routes) {
            final coordinates = route['coordinates'] as List<dynamic>?;
            if (coordinates != null) {
              alternativeRoutes.add(
                coordinates.map<List<double>>((point) {
                  if (point is List && point.length >= 2) {
                    return [point[0].toDouble(), point[1].toDouble()];
                  } else {
                    throw Exception('Unexpected point format: $point');
                  }
                }).toList(),
              );
            }
          }
        }


        if (alternativeRoutes.isNotEmpty) {
          context
              .read<MapBloc>()
              .add(DisplayAlternativeRoutesFromJson(alternativeRoutes));
        } else {
          print('No alternative routes found.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Δεν βρέθηκαν διαδρομές.')),
          );
        }
      } else {
        // Send only the first route as JSON
        context.read<MapBloc>().add(DisplayRouteFromJson(responseJson));
      }
    } catch (e) {
      print("Navigation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Δεν φορτώθηκαν οι οδηγίες. Ξαναπροσπάθησε αργότερα!')),
      );
    }
  }
}
