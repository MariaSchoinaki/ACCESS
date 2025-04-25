// search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController searchController;

  const SearchBar({Key? key, required this.searchController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return
      Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: theme.hintColor, blurRadius: 6)],
          ),
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              return Column(
                children: [
                  TextField(
                    controller: searchController,
                    onSubmitted: (value) {
                      context.read<SearchBloc>().add(SearchQueryChanged(value));
                    },
                    decoration: InputDecoration(
                      hintText: 'Αναζήτηση...',
                      prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      hintStyle: theme.inputDecorationTheme.hintStyle,
                    ),
                  ),
                  if (state is SearchLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (state is SearchLoaded)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.results.length,
                      itemBuilder: (context, index) {
                        final result = state.results[index];
                        return ListTile(
                          title: Text(result.name, style: theme.textTheme.bodyMedium),
                          onTap: () {
                            searchController.text = result.name;
                            FocusScope.of(context).unfocus();
                            context.read<SearchBloc>().add(SearchQueryChanged(""));
                            context.read<SearchBloc>().add(RetrieveCoordinatesEvent(result.id));
                          },
                        );
                      },
                    ),
                  if (state is SearchError)
                    Text('Κάτι πήγε λάθος! Ξαναπροσπάθησε αργότερα. ${state.message}', style: theme.textTheme.bodyMedium),
                ],
              );
            },
          ),
        ),
      );
  }
}
