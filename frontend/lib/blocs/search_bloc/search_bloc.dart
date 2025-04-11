// search_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:access/services/search_service.dart';
import 'package:access/blocs/search_bloc/search_event.dart';
import 'package:access/blocs/search_bloc/search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchService searchService;

  SearchBloc(this.searchService) : super(SearchInitial()) {
    on<SearchQueryChanged>((event, emit) async {
      if (event.query.trim().isEmpty) {
        emit(SearchInitial());
        return;
      }

      emit(SearchLoading());
      try {
        final results = await searchService.searchPlace(event.query);
        emit(SearchLoaded(results));
      } catch (e) {
        emit(SearchError('An error occurred while searching'));
      }
    });
  }
}
