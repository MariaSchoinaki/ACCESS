import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:image_picker/image_picker.dart';

import '../blocs/report_obstacle_bloc/report_obstacle_bloc.dart';

class ReportObstacleScreen extends StatefulWidget {
  const ReportObstacleScreen({super.key});

  @override
  State<ReportObstacleScreen> createState() => _ReportObstacleScreenState();
}

class _ReportObstacleScreenState extends State<ReportObstacleScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _obstacleTypes = [
    'Σπασμένο Πεζοδρόμιο',
    'Παράνομη Στάθμευση',
    'Σκαλιά',
    'Χωρίς Ράμπα',
    'Άλλο',
  ];

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

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
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


  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportObstacleBloc, ReportObstacleState>(
      listener: (context, state) {
        if (state.submissionStatus == SubmissionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Η αναφορά υποβλήθηκε με επιτυχία!'), backgroundColor: Colors.green),
          );
          // To close the screen once submitted
          // Future.delayed(const Duration(seconds: 1), () {
          //   if (mounted) Navigator.of(context).pop();
          // });
        }
        else if (state.submissionStatus == SubmissionStatus.failure && state.errorMessage != null) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) { ///TODO: make all notifications like this
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
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); /// Close the dialog
                    },
                  ),
                ],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            },
          );
          context.read<ReportObstacleBloc>().add(ErrorHandler());
        }
        else if (state.locationStatus == LocationStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${state.errorMessage}'), backgroundColor: Colors.orange),
          );
        }
        if (_descriptionController.text != state.description && state.submissionStatus != SubmissionStatus.submitting) {
          _descriptionController.text = state.description;
          _descriptionController.selection = TextSelection.fromPosition(
              TextPosition(offset: _descriptionController.text.length));
        }
      },
      child: BlocBuilder<ReportObstacleBloc, ReportObstacleState>(
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
              actions: [
                TextButton(
                  onPressed: canInteract ? () => Navigator.of(context).pop() : null,
                  child: const Text('Ακύρωση', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AbsorbPointer(
                  absorbing: isSubmitting,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// LOCATION
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

                      /// CHOOSE FROM MAP
                      //TODO
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

                      /// KIND OF OBSTACLE
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

                      /// DEGREE OF ACCESSIBILITY
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

                      /// DESCRIPTION TEXTFIELD
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

                      /// IMAGE BUTTONS
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

                      /// SUBMISSION
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