import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';

Future<List<Map<String, dynamic>>> fetchCollectionDocuments(
    AuthClient authClient, String projectId, String collection) async {
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection',
  );

  final response = await authClient.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final documents = data['documents'] as List<dynamic>?;

    if (documents == null) {
      print('No documents found in $collection.');
      return [];
    }

    //print('Found ${documents.length} documents in $collection.');

    return documents.map<Map<String, dynamic>>((doc) {
      final docName = doc['name'] as String;
      final fields = doc['fields'] as Map<String, dynamic>;
      return {
        'name': docName,
        'fields': fields,
      };
    }).toList();
  } else {
    print('Failed to fetch documents from $collection: ${response.statusCode} - ${response.body}');
    return [];
  }
}