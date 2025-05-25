import 'package:access/models/mapbox_feature.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

part 'favourites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {

  /// Firebase Authentication service instance. Used to get the current user.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  /// Firestore database service instance. Used to save the report data.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FavoritesCubit() : super(FavoritesInitial()) {
    loadFavorites();
  }

  void loadFavorites() async {
    final currentUser = _auth.currentUser;
    emit(FavoritesLoading());
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('favorites')
          .get();

      final favs = {
        for (var doc in snapshot.docs)
          doc.id: doc.data()
      };

      emit(FavoritesLoaded(favs));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  void toggleFavorite({required feature}) async {
    if (state is! FavoritesLoaded) return;

    final current = Map<String, dynamic>.from((state as FavoritesLoaded).favorites);

    final currentUser = _auth.currentUser;
    final ref = _firestore
        .collection('users')
        .doc(currentUser?.uid)
        .collection('favorites')
        .doc(feature.id);

    if (current.containsKey(feature.id)) {
      await ref.delete();
      current.remove(feature.id);
    } else {
      await ref.set({
        'name': feature.name,
        'location': {'lat': feature.latitude, 'lng': feature.longitude},
      });
      current[feature.id] = {
        'name': feature.name,
        'location': {'lat': feature.latitude, 'lng': feature.longitude},
      };
    }
    emit(FavoritesLoaded(current));
  }

  bool isFavorite(String placeId) {
    if (state is FavoritesLoaded) {
      return (state as FavoritesLoaded).favorites.containsKey(placeId);
    }
    return false;
  }
}
