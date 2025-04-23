import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:access/services/search_service.dart';
import '../../models/mapbox_feature.dart';

part 'search_event.dart';
part 'search_state.dart';

/// Bloc that handles search functionality for querying locations or features
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchService searchService;

  /// Creates a SearchBloc with a required SearchService
  SearchBloc({required this.searchService}) : super(SearchInitial()) {
    // Register event handler for query changes
    on<SearchQueryChanged>(_onSearchQueryChanged);
  }

  /// Handles the search query update
  Future<void> _onSearchQueryChanged(
      SearchQueryChanged event,
      Emitter<SearchState> emit,
      ) async {
    final query = event.query.trim();

    // If query is empty, reset to initial state
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading()); // Set loading state while fetching

    try {
      // Perform the search using the service
      final results = await searchService.search(query);
      emit(SearchLoaded(results)); // Emit loaded state with results
    } catch (e) {
      // Emit error state if something goes wrong
      emit(SearchError('An error occurred while searching: \${e.toString()}'));
    }
  }
}