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