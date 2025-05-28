import 'dart:convert';
import 'dart:io';

/// Class to handle postal code lookups.
class MunicipalityMapping {
  final List<Map<String, String>> dataset;

  MunicipalityMapping(this.dataset);

  /// Factory method to create a MunicipalityMapping from a CSV string.
  factory MunicipalityMapping.fromCsv(String csvString) {
    final lines = LineSplitter().convert(csvString);
    final header = lines.first.split(',');
    final List<Map<String, String>> data = lines.skip(1).map((line) {
      final values = line.split(',');
      return Map.fromIterables(header, values);
    }).toList();
    return MunicipalityMapping(data);
  }

  /// Finds the municipality for a given postal code (string or int).
  String? findMunicipality(String? postalCode) {
    if (postalCode == null) return null;
    final cleaned = postalCode.trim();
    for (var row in dataset) {
      if (row['postal_code'] == cleaned) {
        return row['municipality'];
      }
    }
    return null;
  }

  /// Short alias for findMunicipality, returns 'Άγνωστος' if not found.
  String getMunicipality(String? postalCode) {
    return findMunicipality(postalCode) ?? 'Άγνωστος';
  }
}

Future<void> main() async {
  print('[STEP] Loading postal dataset...');

  final file = File('../../data/postalcode.csv');
  final csvString = await file.readAsString();

  final mapping = MunicipalityMapping.fromCsv(csvString);

  // Example usage:
  final postalCode = '12241';
  final municipality = mapping.getMunicipality(postalCode);

  print('Postal code $postalCode belongs to municipality: $municipality.');
}
