part of 'search_bloc.dart';

/// Base class for all search-related events.
abstract class SearchEvent {}

/// Event triggered when the user updates the search query.
class SearchQueryChanged extends SearchEvent {
  /// The query string typed by the user.
  final String query;

  /// Constructs a [SearchQueryChanged] event with the given [query].
  SearchQueryChanged(this.query);

  @override
  String toString() => 'SearchQueryChanged(query: $query)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SearchQueryChanged &&
              runtimeType == other.runtimeType &&
              query == other.query;

  @override
  int get hashCode => query.hashCode;
}

/// Event triggered to retrieve coordinates based on a Mapbox feature ID.
class RetrieveCoordinatesEvent extends SearchEvent {
  /// The Mapbox feature ID.
  final String mapboxId;

  /// Constructs a [RetrieveCoordinatesEvent] with the given [mapboxId].
  RetrieveCoordinatesEvent(this.mapboxId);
}

/// Event triggered to retrieve the name of a location from coordinates.
class RetrieveNameFromCoordinatesEvent extends SearchEvent {
  /// The latitude of the location.
  final double latitude;

  /// The longitude of the location.
  final double longitude;

  /// Constructs a [RetrieveNameFromCoordinatesEvent] with the given coordinates.
  RetrieveNameFromCoordinatesEvent(this.latitude, this.longitude);
}

/// Event triggered when a category filter button is pressed.
class FilterByCategoryPressed extends SearchEvent {
  /// The selected category string.
  final String category;

  /// Constructs a [FilterByCategoryPressed] event with the given [category].
  FilterByCategoryPressed(this.category);

  @override
  String toString() => 'FilterByCategoryPressed(category: $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FilterByCategoryPressed &&
              runtimeType == other.runtimeType &&
              category == other.category;

  @override
  int get hashCode => category.hashCode;
}

