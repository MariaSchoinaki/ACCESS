part of 'search_bloc.dart';

/// Base class for all states related to the search feature.
abstract class SearchState {}

/// Initial state before any search has been made.
class SearchInitial extends SearchState {
  @override
  String toString() => 'SearchInitial';
}

/// State indicating that a search is currently in progress.
class SearchLoading extends SearchState {
  @override
  String toString() => 'SearchLoading';
}

/// State representing successfully loaded search results.
class SearchLoaded extends SearchState {
  /// The list of features returned from the search.
  final List<MapboxFeature> results;

  /// Creates a [SearchLoaded] state with the provided [results].
  SearchLoaded(this.results);

  @override
  String toString() => 'SearchLoaded(results: ${results.length} items)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SearchLoaded &&
              runtimeType == other.runtimeType &&
              results == other.results;

  @override
  int get hashCode => results.hashCode;
}

/// State representing an error occurred during the search.
class SearchError extends SearchState {
  /// The error message describing the failure.
  final String message;

  /// Creates a [SearchError] state with the provided [message].
  SearchError(this.message);

  @override
  String toString() => 'SearchError(message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SearchError &&
              runtimeType == other.runtimeType &&
              message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// State indicating that coordinates are being fetched.
class CoordinatesLoading extends SearchState {}

/// State representing successfully retrieved coordinates for a feature.
class CoordinatesLoaded extends SearchState {
  /// The feature containing the coordinates.
  final MapboxFeature feature;

  /// Creates a [CoordinatesLoaded] state with the provided [feature].
  CoordinatesLoaded(this.feature);
}

/// State indicating an error occurred during coordinate retrieval.
class CoordinatesError extends SearchState {
  /// The error message.
  final String message;

  /// Creates a [CoordinatesError] state with the provided [message].
  CoordinatesError(this.message);
}

/// State indicating that a name-based lookup is in progress.
class NameLoading extends SearchState {}

/// State representing successfully retrieved name information for a feature.
class NameLoaded extends SearchState {
  /// The feature retrieved by name.
  final MapboxFeature feature;

  /// Creates a [NameLoaded] state with the provided [feature].
  NameLoaded(this.feature);
}

/// State indicating an error occurred during name lookup.
class NameError extends SearchState {
  /// The error message.
  final String message;

  /// Creates a [NameError] state with the provided [message].
  NameError(this.message);
}


/// State representing the loaded results for a specific category.
class CategoryResultsLoaded extends SearchState {
  /// The list of features loaded for the category.
  final List<MapboxFeature> features;

  /// Constructs a [CategoryResultsLoaded] state with the given [features].
  CategoryResultsLoaded(this.features);
}