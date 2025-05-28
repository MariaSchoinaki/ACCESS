import 'package:access_models/firebase/rest.dart';
import 'package:access_models/municipality_mapping.dart';

class StatisticsService {
  final FirestoreRest rest;
  final MunicipalityMapping municipalityMapping;

  StatisticsService(this.rest, this.municipalityMapping);

  /// Extracts the postal code (TK) from a location description string.
  String extractPostalCode(String? locationDescription) {
    if (locationDescription == null) return 'Unknown';
    final cleaned = locationDescription.replaceAll(' ', '');
    final regex = RegExp(r'(\d{5})');
    final match = regex.firstMatch(cleaned);
    if (match != null) {
      return match.group(1)!;
    }
    return 'Unknown';
  }

  /// Returns the municipality name for a given location description (uses postal code).
  String getMunicipalityFromPostal(String? locationDescription) {
    final postalCode = extractPostalCode(locationDescription);
    if (postalCode == 'Unknown') return 'Unknown';
    // Uses the MunicipalityMapping to get the municipality.
    return municipalityMapping.findMunicipality(postalCode) ?? 'Unknown';
  }

  /// Extracts the location description from a Firestore report document's fields.
  String getLocationDescription(Map<String, dynamic> fields) {
    final locDesc = fields['locationDescription'];
    if (locDesc is Map && locDesc.containsKey('stringValue')) {
      return locDesc['stringValue'] ?? '';
    }
    if (locDesc is String) {
      return locDesc;
    }
    return '';
  }

  /// Returns a map with report counts and all reports per municipality.
  Future<Map<String, dynamic>> statsAndReportsPerMunicipality() async {
    final userReports = await rest.fetchCollectionDocuments('reports');
    final municipalReports = await rest.fetchCollectionDocuments('municipal_reports');
    final allReports = [...userReports, ...municipalReports];

    final Map<String, int> countPerMunicipality = {};
    final Map<String, List<Map<String, dynamic>>> reportsPerMunicipality = {};

    for (final report in allReports) {
      final fields = report['fields'] as Map<String, dynamic>;
      final location = getLocationDescription(fields);
      final municipality = getMunicipalityFromPostal(location);

      countPerMunicipality[municipality] = (countPerMunicipality[municipality] ?? 0) + 1;
      reportsPerMunicipality.putIfAbsent(municipality, () => []).add(fields);
    }

    return {
      "counts": countPerMunicipality,
      "reports": reportsPerMunicipality,
    };
  }
}