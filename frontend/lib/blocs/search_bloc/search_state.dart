import 'package:access/models/mapbox_feature.dart';

/// Base class for all states related to the search feature
abstract class SearchState {}

/// Initial state before any search has been made
class SearchInitial extends SearchState {
  @override
  String toString() => 'SearchInitial';
}

/// State indicating that a search is in progress
class SearchLoading extends SearchState {
  @override
  String toString() => 'SearchLoading';
}

/// State representing successfully loaded search results
class SearchLoaded extends SearchState {
  final List<MapboxFeature> results;

  SearchLoaded(this.results);

  @override
  String toString() => 'SearchLoaded(results: \${results.length} items)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SearchLoaded &&
              runtimeType == other.runtimeType &&
              results == other.results;

  @override
  int get hashCode => results.hashCode;
}

/// State representing an error occurred during search
class SearchError extends SearchState {
  final String message;

  SearchError(this.message);

  @override
  String toString() => 'SearchError(message: \$message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SearchError &&
              runtimeType == other.runtimeType &&
              message == other.message;

  @override
  int get hashCode => message.hashCode;
}