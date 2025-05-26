import 'package:access/web_screens/web_bloc/web_report_card_bloc/report_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:access/theme/app_colors.dart';

class ReportCard extends StatefulWidget {
  const ReportCard({Key? key}) : super(key: key);

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  final TextEditingController _damageReportController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  List<double>? selectedCoordinates;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedProjectType;
  String? _accessibility;

  final List<String> _projectTypes = [
    'Ανακαίνιση πεζοδρομίου',
    'Αποκατάσταση οδοστρώματος',
    'Εργασίες φωτισμού',
    'Διαμόρφωση πάρκου',
    'Άλλο',
  ];

  final List<String> _accessibilityType = [
    'Καθόλου Προσβάσιμο',
    'Δύσκολα Προσβάσιμο',
    'Μέτρια Προσβάσιμο',
  ];

  @override
  void dispose() {
    _damageReportController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary, // header background + active date
              onPrimary: Colors.white,     // text on primary color
              onSurface: Colors.black,     // default text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
            dialogTheme: DialogTheme(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    return picked;
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDate();
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate();
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _submitForm() {
    final location = _locationController.text.trim();

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "Άγνωστο email";
    final userId = user?.uid ?? "Άγνωστο ID";

    if (_startDate == null || _endDate == null || _selectedProjectType == null || location.isEmpty || selectedCoordinates?[0] == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Συμπλήρωσε όλα τα απαιτούμενα πεδία.")),
      );
      return;
    }else{
      context.read<ReportBloc>().add(
        SubmitReport(
          locationDescription: _locationController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          obstacleType: _selectedProjectType!,
          description: _damageReportController.text.trim(),
          accessibility: _accessibility,
          coordinates: selectedCoordinates,
          needsUpdate: true,
          needsImprove: true,
          timestamp: DateTime.now(),
          userEmail: email,
          userId: userId,
        ),
      );
    }
  }

  void _handleSearchResult(BuildContext context, SearchState state) {
    if (state is SearchLoaded) {
      if (state.results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Δεν βρέθηκε τοποθεσία. Δοκίμασε ξανά.")),
        );
      }
    } else if (state is SearchError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Σφάλμα αναζήτησης: ${state.message}")),
      );
    }
    else if (state is CoordinatesLoaded){
      selectedCoordinates = [state.feature.longitude, state.feature.latitude];
    }
  }

  void _handleReportResult(BuildContext context, ReportState state) {
    if (state is ReportSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Η αναφορά υποβλήθηκε επιτυχώς!")),
      );
    } else if (state is ReportFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Σφάλμα: ${state.error}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<SearchBloc, SearchState>(
      listener: _handleSearchResult,
      child: BlocListener<ReportBloc, ReportState>(
        listener: _handleReportResult,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Αναφορά έργου δήμου:", style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),

                const Text("Τοποθεσία έργου", style: TextStyle(fontSize:16)),
                const SizedBox(height: 6),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(hintText: 'Πληκτρολόγησε διεύθυνση'),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty){
                      context.read<SearchBloc>().add(SearchQueryChanged(value));
                    }
                  }
                ),
                BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    if (state is SearchLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (state is SearchLoaded) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.results.length,
                        itemBuilder: (context, index) {
                          final feature = state.results[index];
                          return ListTile(
                            title: Text(feature.fullAddress),
                            onTap: () {
                              _locationController.text = feature.fullAddress;
                              context.read<SearchBloc>().add(SearchQueryChanged(""));
                              context.read<SearchBloc>().add(RetrieveCoordinatesEvent(feature.id));
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 16),
                const Text("Περίοδος εκτέλεσης έργου", style: TextStyle(fontSize:16)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: ButtonStyle(
                          side: WidgetStateProperty.resolveWith<BorderSide>((states){
                            if (states.contains(WidgetState.hovered)) {
                              return BorderSide(color: AppColors.grey, width: 1); // hover stroke
                            }
                            return BorderSide(color: AppColors.grey, width: 1);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith<Color>((states){
                            if (states.contains(WidgetState.hovered)) {
                              return AppColors.primary; // hover text color
                            }
                            return AppColors.blackAccent[700]!;
                          }),
                          overlayColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.1)), // ripple hover
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        onPressed: _pickStartDate,
                        child: Text(_startDate != null
                            ? "Από: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"
                            : "Ημερομηνία έναρξης", style: TextStyle(fontSize:14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: ButtonStyle(
                          side: WidgetStateProperty.resolveWith<BorderSide>((states){
                            if (states.contains(WidgetState.hovered)) {
                              return BorderSide(color: AppColors.grey, width: 1); // hover stroke
                            }
                            return BorderSide(color: AppColors.grey, width: 1);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith<Color>((states){
                            if (states.contains(WidgetState.hovered)) {
                              return AppColors.primary; // hover text color
                            }
                            return AppColors.blackAccent[700]!;
                          }),
                          overlayColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.1)), // ripple hover
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        onPressed: _pickEndDate,
                        child: Text(_endDate != null
                            ? "Έως: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"
                            : "Ημερομηνία λήξης", style: TextStyle(fontSize:14)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text("Τύπος έργου", style: TextStyle(fontSize:16)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedProjectType,
                  items: _projectTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedProjectType = value),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

                const SizedBox(height: 16),
                const Text("Αναφορά έργου (προαιρετικά)", style: TextStyle(fontSize:16)),
                const SizedBox(height: 6),
                TextField(
                  controller: _damageReportController,
                  decoration: InputDecoration(
                    hintText: "Περιγράψτε τυχόν ενέργειες",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),
                const Text("Βαθμός Δυσκολίας", style: TextStyle(fontSize:16)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _accessibility,
                  items: _accessibilityType
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _accessibility = value),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Κλείσιμο"),
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.red; // χρώμα κειμένου στο hover
                          }
                          return AppColors.black; // κανονικό χρώμα κειμένου
                        }),
                        textStyle: WidgetStateProperty.all(
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    BlocBuilder<ReportBloc, ReportState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is ReportLoading ? null : _submitForm,
                          child: state is ReportLoading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Text("Υποβολή"),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
