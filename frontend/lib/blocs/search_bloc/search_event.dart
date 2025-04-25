part of 'search_bloc.dart';

/// Base class for all search-related events
abstract class SearchEvent {}

/// Event triggered when the search query is updated
class SearchQueryChanged extends SearchEvent {
  /// The query string typed by the user
  final String query;

  /// Constructs a SearchQueryChanged event with the given query
  SearchQueryChanged(this.query);

  @override
  String toString() => 'SearchQueryChanged(query: \$query)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SearchQueryChanged &&
              runtimeType == other.runtimeType &&
              query == other.query;

  @override
  int get hashCode => query.hashCode;
}

class RetrieveCoordinatesEvent extends SearchEvent {
  final String mapboxId;

  RetrieveCoordinatesEvent(this.mapboxId);
}

class RetrieveNameFromCoordinatesEvent extends SearchEvent {
  final double latitude;
  final double longitude;

  RetrieveNameFromCoordinatesEvent(this.latitude, this.longitude);
}

/// Event triggered when a category filter button is pressed
class FilterByCategoryPressed extends SearchEvent {
  final String category;

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

/// Event dispatched when category search results are loaded
class CategoryResultsLoaded extends SearchState {
  final List<MapboxFeature> features;

  CategoryResultsLoaded(this.features);
}