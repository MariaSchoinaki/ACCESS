import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ACCESS/blocs/search_bloc/search_event.dart';
import 'package:ACCESS/blocs/search_bloc/search_state.dart';
import 'package:ACCESS/services/search_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchService searchService;

  SearchBloc({required this.searchService}) : super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
  }

  Future<void> _onSearchQueryChanged(
      SearchQueryChanged event,
      Emitter<SearchState> emit,
      ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      final results = await searchService.search(query);
      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError('An error occurred while searching: ${e.toString()}'));
    }
  }
}

