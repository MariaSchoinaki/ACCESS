import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Firestore REST API client for reading and writing documents.
class FirestoreRest {
  final String projectId, clientEmail, privateKey;
  String? _token;
  DateTime? _expiry;

  FirestoreRest._(this.projectId, this.clientEmail, this.privateKey);

  /// Creates a FirestoreRest instance from a Google service account JSON file.
  factory FirestoreRest.fromServiceAccount(String path) {
    final j = jsonDecode(File(path).readAsStringSync());
    return FirestoreRest._(
      j['project_id'] as String,
      j['client_email'] as String,
      j['private_key'] as String,
    );
  }

  /// Returns a valid OAuth token for Firestore requests, creating one if necessary.
  Future<String> getToken(String scope) async {
    //if (_token != null && _expiry != null && _expiry!.isAfter(DateTime.now())) return _token!;
    final now = DateTime.now().toUtc();
    final jwt = JWT({
      'iss': clientEmail,
      'sub': clientEmail,
      'scope': scope,
      'aud': 'https://oauth2.googleapis.com/token',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    });
    final signed = jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);
    final resp = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': signed
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('OAuth token error: ${resp.body}');
    }
    final d = jsonDecode(resp.body) as Map<String, dynamic>;
    _token = d['access_token'] as String;
    _expiry = now.add(Duration(seconds: d['expires_in'] as int));
    return _token!;
  }

  /// Low-level: Returns the raw list of documents from a Firestore collection.
  Future<List<Map<String, dynamic>>> listDocs(String path) async {
    final t = await getToken('https://www.googleapis.com/auth/datastore');
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$path',
    );
    final r = await http.get(url, headers: {'Authorization': 'Bearer $t'});
    if (r.statusCode != 200) {
      throw Exception('List $path failed: ${r.body}');
    }
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    return (b['documents'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  /// High-level: Returns a list of maps with 'name' and 'fields' for each document in a collection.
  /// This is compatible with the format your project expects.
  Future<List<Map<String, dynamic>>> fetchCollectionDocuments(String collection) async {
    final docs = await listDocs(collection);
    return docs.map<Map<String, dynamic>>((doc) {
      final docName = doc['name'] as String;
      final fields = doc['fields'] as Map<String, dynamic>;
      return {
        'name': docName,
        'fields': fields,
      };
    }).toList();
  }

  /// Updates a document (PATCH). Use updateMaskFields to only update specific fields if needed.
  Future<void> patchDoc(String path, String docId, Map<String, dynamic> fields, {List<String>? updateMaskFields}) async {
    final t = await getToken('https://www.googleapis.com/auth/datastore');
    String urlStr = 'https://firestore.googleapis.com/v1/projects/$projectId'
        '/databases/(default)/documents/$path/$docId';
    if (updateMaskFields != null && updateMaskFields.isNotEmpty) {
      final mask = updateMaskFields.map((f) => 'updateMask.fieldPaths=$f').join('&');
      urlStr += '?$mask';
    }
    final url = Uri.parse(urlStr);
    final resp = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $t',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'fields': fields}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Patch $path/$docId failed: ${resp.body}');
    }
  }

  /// Retrieves a single document by collection path and document ID.
  Future<Map<String, dynamic>> getDoc(String path, String docId) async {
    final t = await getToken('https://www.googleapis.com/auth/datastore');
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
          '/databases/(default)/documents/$path/$docId',
    );
    final r = await http.get(url, headers: {'Authorization': 'Bearer $t'});
    if (r.statusCode != 200) {
      throw Exception('Get $path/$docId failed: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}
