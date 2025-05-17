import 'package:access/web_screens/web_bloc/report_cart_bloc/report_bloc.dart';
import 'package:access/web_screens/web_bloc/report_cart_bloc/report_event.dart';
import 'package:access/web_screens/web_bloc/report_cart_bloc/report_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class ReportCart extends StatefulWidget {

  const ReportCart({
    Key? key,
  }) : super(key: key);

  @override
  State<ReportCart> createState() => _ReportCartState();
}

class _ReportCartState extends State<ReportCart> {
  final TextEditingController _damageReportController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedProjectType;

  final List<String> _projectTypes = [
    'Ανακαίνιση πεζοδρομίου',
    'Αποκατάσταση οδοστρώματος',
    'Εργασίες φωτισμού',
    'Διαμόρφωση πάρκου',
    'Άλλο',
  ];

  @override
  void dispose() {
    _damageReportController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _submitForm() {
    final location = _locationController.text.trim();
    final damageReport = _damageReportController.text.trim();

    if (_startDate == null || _endDate == null || _selectedProjectType == null || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Συμπλήρωσε όλα τα απαιτούμενα πεδία.")),
      );
      return;
    }

    context.read<ReportBloc>().add(
      SubmitReport(
        location: location,
        startDate: _startDate!,
        endDate: _endDate!,
        projectType: _selectedProjectType!,
        damageReport: damageReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Η αναφορά υποβλήθηκε επιτυχώς!")),
          );
        } else if (state is ReportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Σφάλμα: ${state.error}")),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Αναφορά έργου δήμου:",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              const Text("Τοποθεσία έργου"),
              const SizedBox(height: 6),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: "Π.χ. Οδός Αθηνάς 23",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),

              const Text("Περίοδος εκτέλεσης έργου"),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStartDate,
                      child: Text(_startDate != null
                          ? "Από: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"
                          : "Επιλέξτε ημερομηνία έναρξης"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEndDate,
                      child: Text(_endDate != null
                          ? "Έως: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"
                          : "Επιλέξτε ημερομηνία λήξης"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text("Τύπος έργου"),
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

              const Text("Αναφορά έργου (προαιρετικά)"),
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

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Κλείσιμο"),
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
    );
  }
}
