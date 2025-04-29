import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';
import 'category_filter_button.dart';

/// A widget that displays a search input field, search results (or loading/error states),
/// and category filter buttons. Interacts with a [SearchBloc] to handle search logic.
class SearchBar extends StatelessWidget {
  /// The controller for the search text input field.
  final TextEditingController searchController;

  /// Creates a SearchBar widget.
  ///
  /// Requires a [searchController] to manage the text field's content.
  const SearchBar({Key? key, required this.searchController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// the current theme data.
    final theme = Theme.of(context);

    // Main container for the search bar area.
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container for the search input and results area.
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: theme.hintColor.withOpacity(0.3), blurRadius: 6)], // Adjusted opacity for subtlety
            ),
            // Use BlocBuilder to react to SearchBloc state changes.
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                // Build the inner column containing the text field and results/status.
                return Column(
                  children: [
                    /// The text input field for searching.
                    TextField(
                      controller: searchController, // Link to the provided controller.
                      // When the user submits the search (e.g., presses Enter).
                      onSubmitted: (value) {
                        // Dispatch an event to the SearchBloc with the query.
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
                    /// --- Conditional UI based on SearchState ---
                    // Show a loading indicator if the state is SearchLoading.
                    if (state is SearchLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    // Show the results list if the state is SearchLoaded.
                    if (state is SearchLoaded)
                      ListView.builder(
                        shrinkWrap: true, // Prevent ListView from taking infinite height.
                        // Disable scrolling for this inner ListView (parent ScrollView handles it).
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.results.length, // Number of results.
                        itemBuilder: (context, index) {
                          // Get the individual result data.
                          final result = state.results[index];
                          // Display each result as a ListTile.
                          return ListTile(
                            title: Text(result.name, style: theme.textTheme.bodyMedium),
                            // Action when a result item is tapped.
                            onTap: () {
                              // Update the search bar text with the selected result name.
                              searchController.text = result.name;
                              // Remove focus from the text field (hides keyboard).
                              FocusScope.of(context).unfocus();
                              // Dispatch event to clear search query (or reset state).
                              context.read<SearchBloc>().add(SearchQueryChanged(""));
                              // Dispatch event to fetch details/coordinates for the selected result ID.
                              context.read<SearchBloc>().add(RetrieveCoordinatesEvent(result.id));
                            },
                          );
                        },
                      ),
                    // Show an error message if the state is SearchError.
                    if (state is SearchError)
                      Padding( // Add padding around the error message
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Κάτι πήγε λάθος! Ξαναπροσπάθησε αργότερα. ${state.message}',
                           style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error) // Use error color
                         ),
                      ),
                  ],
                );
              },
            ),
          ),
          // Spacing between the search area and filter buttons.
          const SizedBox(height: 8),
          // Horizontally scrolling row for category filter buttons.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                /// --- Category Filter Buttons ---
                CategoryFilterButton(
                  label: 'Καφετέριες', // Display label
                  categoryKey: 'coffee',   // Key for the event
                ),
                const SizedBox(width: 8.0), // Spacing between buttons.

                CategoryFilterButton(
                  label: 'Εστιατόρια', // Display label
                  categoryKey: 'restaurant',// Key for the event
                ),
                const SizedBox(width: 8.0), // Spacing between buttons.

                CategoryFilterButton(
                  label: 'Parking',     // Display label
                  categoryKey: 'parking',   // Key for the event
                ),

                // Add some padding at the end of the scrollable row.
                const SizedBox(width: 16.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}