import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';


/// A reusable button widget for category filtering in the search bar.
///
/// Displays a label and dispatches a [FilterByCategoryPressed] event
/// with the associated [categoryKey] when pressed.
class CategoryFilterButton extends StatelessWidget {
  /// The text label displayed on the button.
  final String label;
  /// The internal key representing the category (e.g., 'coffee', 'restaurant').
  /// This value is passed to the [FilterByCategoryPressed] event.
  final String categoryKey;

  /// Creates a CategoryFilterButton.
  const CategoryFilterButton({
    Key? key,
    required this.label,
    required this.categoryKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // Use the same styling as the original buttons
        backgroundColor: theme.cardColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        // You might want to adjust padding or other style properties here if needed
      ),
      onPressed: () {
        print('Selected category: $label (key: $categoryKey)');
        // Dispatch the event to the SearchBloc using the provided categoryKey
        context.read<SearchBloc>().add(FilterByCategoryPressed(categoryKey));
      },
      // Use the provided label for the button's text
      child: Text(label),
    );
  }
}