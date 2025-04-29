import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/report_obstacle_bloc/report_obstacle_bloc.dart';

/// Screen for reporting accessibility obstacles
///
/// Handles:
/// - Obstacle type selection
/// - Location tracking/mapping
/// - Accessibility rating selection
/// - Image attachments
/// - Report submission to backend
class ReportObstacleScreen extends StatefulWidget {
  const ReportObstacleScreen({super.key});

  @override
  State<ReportObstacleScreen> createState() => _ReportObstacleScreenState();
}

/// Manages state for the obstacle reporting screen
///
/// Maintains:
/// - Text controller for description
/// - BLoC event handling
/// - UI state synchronization
class _ReportObstacleScreenState extends State<ReportObstacleScreen> {
  /// Controller for obstacle description text input
  final TextEditingController _descriptionController = TextEditingController();

  /// Predefined obstacle types in Greek
  ///
  /// Options:
  /// - Σπασμένο Πεζοδρόμιο (Broken sidewalk)
  /// - Παράνομη Στάθμευση (Illegal parking)
  /// - Σκαλιά (Stairs)
  /// - Χωρίς Ράμπα (No ramp)
  /// - Άλλο (Other)
  final List<String> _obstacleTypes = [
    'Σπασμένο Πεζοδρόμιο',
    'Παράνομη Στάθμευση',
    'Σκαλιά',
    'Χωρίς Ράμπα',
    'Άλλο',
  ];

  /// Initializes BLoC communication and text controller
  ///
  /// Actions:
  /// 1. Loads initial location data
  /// 2. Sets up text controller listener
  @override
  void initState() {
    super.initState();
    context.read<ReportObstacleBloc>().add(LoadInitialDataRequested());
    _descriptionController.addListener(() {
      final currentStateDescription = context.read<ReportObstacleBloc>().state.description;
      if (_descriptionController.text != currentStateDescription) {
        context.read<ReportObstacleBloc>().add(DescriptionChanged(_descriptionController.text));
      }
    });
  }

  /// Cleans up resources
  ///
  /// Disposes:
  /// - Text controller to prevent memory leaks
  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Builds a selectable chip for obstacle types
  ///
  /// Parameters:
  /// - [context]: Current build context
  /// - [state]: Current BLoC state
  /// - [type]: Obstacle type in Greek
  ///
  /// Returns:
  /// [ChoiceChip] with dynamic selection state
  Widget _buildObstacleTypeChip(BuildContext context, ReportObstacleState state, String type) {
    final isSelected = state.selectedObstacleType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (_) {
        context.read<ReportObstacleBloc>().add(ObstacleTypeSelected(type));
      },
      disabledColor: Colors.grey.shade300,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  /// Builds accessibility rating chips with color coding
  ///
  /// Parameters:
  /// - [context]: Current build context
  /// - [state]: Current BLoC state
  /// - [label]: Accessibility level in Greek
  /// - [color]: Chip color when selected
  ///
  /// Returns:
  /// [ChoiceChip] with accessibility rating options
  Widget _buildAccessibilityOptionChip(BuildContext context, ReportObstacleState state, String label, Color color) {
    final isSelected = state.accessibilityRating == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
      selectedColor: color,
      selected: isSelected,
      onSelected: (_) {
        context.read<ReportObstacleBloc>().add(AccessibilityRatingSelected(label));
      },
      disabledColor: Colors.grey.shade300,
    );
  }

  /// Main build method for the obstacle reporting screen
  ///
  /// Returns:
  /// - BlocListener for state management
  /// - BlocBuilder for reactive UI updates
  /// - Scaffold with app bar and form content
  ///
  /// Handles:
  /// - Success/failure state feedback
  /// - Location data display
  /// - User interaction management
  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportObstacleBloc, ReportObstacleState>(
      /// Handles state changes and UI feedback
      listener: (context, state) {
        /// Show success notification
        if (state.submissionStatus == SubmissionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Η αναφορά υποβλήθηκε με επιτυχία!'), backgroundColor: Colors.green),
          );
        }
        /// Show error dialog on submission failure
        else if (state.submissionStatus == SubmissionStatus.failure && state.errorMessage != null) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text(
                  'Σφάλμα Υποβολής',
                  style: TextStyle(color: Colors.redAccent),
                ),
                content: SingleChildScrollView(
                  child: Text(state.errorMessage!),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Εντάξει'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            },
          );
          context.read<ReportObstacleBloc>().add(ErrorHandler());
        }
        /// Show location error snackbar
        else if (state.locationStatus == LocationStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${state.errorMessage}'), backgroundColor: Colors.orange),
          );
        }
        /// Synchronize description text with controller
        if (_descriptionController.text != state.description && state.submissionStatus != SubmissionStatus.submitting) {
          _descriptionController.text = state.description;
          _descriptionController.selection = TextSelection.fromPosition(
              TextPosition(offset: _descriptionController.text.length));
        }
      },
      child: BlocBuilder<ReportObstacleBloc, ReportObstacleState>(
        /// Builds reactive UI based on current state
        builder: (context, state) {
          final isSubmitting = state.submissionStatus == SubmissionStatus.submitting;
          final isLocationLoading = state.locationStatus == LocationStatus.loading;
          final bool canInteract = !isSubmitting;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: canInteract ? () => Navigator.of(context).pop() : null,
              ),
              title: const Text('Αναφορά Εμποδίου'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AbsorbPointer(
                absorbing: isSubmitting,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Location display section
                    /// Shows either:
                    /// - Loading indicator
                    /// - Location coordinates
                    /// - Error message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.black54),
                          const SizedBox(width: 8),
                          if (isLocationLoading)
                            const Row(
                              children: [
                                SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text("Φόρτωση τοποθεσίας...", style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          else if (state.userLocation != null)
                            Expanded(child: Text(state.userLocation!, style: const TextStyle(fontSize: 16)))
                          else
                            const Expanded(child: Text('Δεν ορίστηκε τοποθεσία', style: TextStyle(fontSize: 16, color: Colors.grey))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// Map selection button
                    /// TODO: Implement map selection functionality
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: canInteract
                            ? () => context.read<ReportObstacleBloc>().add(SelectLocationOnMapRequested())
                            : null,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Διάλεξε από Χάρτη'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Obstacle type selection chips
                    /// Displays predefined obstacle types in Greek
                    const Text('Είδος Εμποδίου:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _obstacleTypes
                          .map((type) => Opacity(
                          opacity: canInteract ? 1.0 : 0.5,
                          child: _buildObstacleTypeChip(context, state, type)))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    /// Accessibility rating selection
                    /// Color-coded options from red (worst) to yellow (medium)
                    const Text('Βαθμός Προσβασιμότητας:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Opacity(opacity: canInteract ? 1.0 : 0.5, child: _buildAccessibilityOptionChip(context, state, 'Καθόλου Προσβάσιμο', Colors.red)),
                        Opacity(opacity: canInteract ? 1.0 : 0.5, child: _buildAccessibilityOptionChip(context, state, 'Δύσκολα Προσβάσιμο', Colors.orange)),
                        Opacity(opacity: canInteract ? 1.0 : 0.5, child: _buildAccessibilityOptionChip(context, state, 'Μέτρια Προσβάσιμο', Colors.yellow.shade700)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    /// Optional description text field
                    /// Character limit: None
                    const Text('Περιγραφή (προαιρετική):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Περιέγραψε το εμπόδιο...',
                      ),
                      enabled: canInteract,
                    ),
                    const SizedBox(height: 24),

                    /// Image capture/upload section
                    /// Allows both camera and gallery selection
                    const Text('Φωτογραφία:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: canInteract
                                ? () => context.read<ReportObstacleBloc>().add(const PickImageRequested(ImageSource.camera))
                                : null,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Άνοιγμα Κάμερας'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: canInteract
                                ? () => context.read<ReportObstacleBloc>().add(const PickImageRequested(ImageSource.gallery))
                                : null,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Ανέβασμα από Gallery'),
                          ),
                        ),
                      ],
                    ),

                    /// Image preview and removal
                    if (state.pickedImage != null) ...[
                      const SizedBox(height: 12),
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              state.pickedImage!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (canInteract)
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black.withOpacity(0.6),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 18,
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  tooltip: 'Αφαίρεση εικόνας',
                                  onPressed: () => context.read<ReportObstacleBloc>().add(RemoveImageRequested()),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),

                    /// Submission button with loading state
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: canInteract
                            ? () => context.read<ReportObstacleBloc>().add(SubmitReportRequested())
                            : null,
                        child: isSubmitting
                            ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ))
                            : const Text('Υποβολή Αναφοράς'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            ),
          );
        },
      ),
    );
  }
}