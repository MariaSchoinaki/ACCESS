import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';
import 'VoiceInputModal.dart';
import 'category_filter_button.dart';

// SearchBar is a StatefulWidget that provides a search input field
// and integrates with voice input and category filtering functionalities.
class SearchBar extends StatefulWidget {
  // Controller for the text input field.
  final TextEditingController searchController;

  // Constructor for the SearchBar widget, requiring the searchController.
  const SearchBar({Key? key, required this.searchController}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

// _SearchBarState is the State class for the SearchBar widget.
// It manages the internal state and logic for the search bar.
class _SearchBarState extends State<SearchBar> {
  // Method to open the voice input modal bottom sheet.
  void _openVoiceInputModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false, // Prevents the modal from taking up the full screen height.
      backgroundColor: Colors.white, // Sets the background color of the modal.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // Rounds the top corners of the modal.
      ),
      builder: (context) {
        // Builds the content of the modal using the VoiceInputModal widget,
        // passing the search controller to it.
        return VoiceInputModal(controller: widget.searchController);
      },
    );
  }

  @override
  // Builds the visual representation of the SearchBar widget.
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Gets the current theme of the application.

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 5), // Adds padding around the search bar container.
      child: BlocBuilder<SearchBloc, SearchState>(
        // BlocBuilder listens to changes in the SearchBloc and rebuilds
        // the widget based on the current state.
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns children to the start of the column.
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor, // Uses the card color from the theme for the background.
                  borderRadius: BorderRadius.circular(12), // Rounds the corners of the container.
                  boxShadow: [BoxShadow(color: theme.hintColor.withOpacity(0.3), blurRadius: 6)], // Adds a subtle shadow.
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: widget.searchController, // Links the text field to the provided controller.
                      onSubmitted: (value) {
                        // Called when the user submits the text in the field.
                        context.read<SearchBloc>().add(SearchQueryChanged(value)); // Dispatches a search event.
                      },
                      decoration: InputDecoration(
                        hintText: 'Αναζήτηση...', // Placeholder text for the input field.
                        prefixIcon: Icon(Icons.search, color: theme.iconTheme.color), // Search icon at the beginning.
                        suffixIcon: IconButton(
                          icon: Icon(Icons.mic, color: theme.iconTheme.color), // Microphone icon at the end.
                          onPressed: _openVoiceInputModal, // Opens the voice input modal when pressed.
                        ),
                        border: InputBorder.none, // Removes the default border of the input field.
                        contentPadding: const EdgeInsets.all(12), // Adds padding inside the input field.
                        hintStyle: theme.inputDecorationTheme.hintStyle, // Uses the hint style from the theme.
                      ),
                    ),
                    if (state is SearchLoaded)
                      const Divider(height: 1, thickness: 1, color: Colors.grey), // Shows a divider when search results are loaded.
                    if (state is SearchLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(), // Shows a loading indicator during search.
                      ),
                    if (state is SearchLoaded)
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true, // Allows the ListView to take only the necessary height.
                        physics: const NeverScrollableScrollPhysics(), // Disables scrolling within the ListView.
                        itemCount: state.results.length, // The number of search results to display.
                        itemBuilder: (context, index) {
                          final result = state.results[index]; // Gets the current search result.
                          return ListTile(
                            title: Text(result.name, style: theme.textTheme.titleMedium), // Displays the name of the result.
                            subtitle: Text(
                              result.fullAddress,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor), // Displays the address.
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis, // Handles long addresses with ellipsis.
                            ),
                            onTap: () {
                              // Called when a search result is tapped.
                              widget.searchController.text = result.name; // Updates the text field with the selected name.
                              FocusScope.of(context).unfocus(); // Removes focus from the text field.
                              context.read<SearchBloc>().add(SearchQueryChanged("")); // Clears previous search.
                              context.read<SearchBloc>().add(RetrieveCoordinatesEvent(result.id)); // Triggers coordinate retrieval.
                            },
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(height: 0.5, thickness: 0.5), // Adds a divider between list items.
                      ),
                    if (state is SearchError)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Κάτι πήγε λάθος! Ξαναπροσπάθησε αργότερα. ${state.message}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error), // Displays an error message.
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (state is! SearchLoaded)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Allows horizontal scrolling for category buttons.
                  child: Row(
                    children: const [
                      CategoryFilterButton(label: 'Καφετέριες', categoryKey: 'coffee', icon: Icons.coffee), // Category filter button for 'Καφετέριες'.
                      SizedBox(width: 8.0),
                      CategoryFilterButton(label: 'Εστιατόρια', categoryKey: 'restaurant', icon: Icons.restaurant), // Category filter button for 'Εστιατόρια'.
                      SizedBox(width: 8.0),
                      CategoryFilterButton(label: 'Υγεία', categoryKey: 'health_services', icon: Icons.health_and_safety), // Category filter button for 'health services'.
                      SizedBox(width: 16.0),
                      CategoryFilterButton(label: 'Parking', categoryKey: 'parking', icon: Icons.local_parking), // Category filter button for 'Parking'.
                      SizedBox(width: 16.0),
                      CategoryFilterButton(label: 'Ψώνια', categoryKey: 'shopping', icon: Icons.shopping_bag), // Category filter button for 'shopping stores'.
                      SizedBox(width: 16.0),
                      CategoryFilterButton(label: 'Μπαρ', categoryKey: 'nightlife', icon: Icons.nightlife), // Category filter button for 'bars'.
                      SizedBox(width: 16.0),
                      CategoryFilterButton(label: 'Ξενοδοχεία', categoryKey: 'hotel', icon: Icons.hotel), // Category filter button for 'hotels'.
                      SizedBox(width: 16.0),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}