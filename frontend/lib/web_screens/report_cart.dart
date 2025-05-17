import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class ReportCart extends StatefulWidget {
  final VoidCallback onWorkPeriodReport;
  final VoidCallback onDamageReport;

  const ReportCart({
    Key? key,
    required this.onWorkPeriodReport,
    required this.onDamageReport,
  }) : super(key: key);

  @override
  State<ReportCart> createState() => _ReportCartState();
}

class _ReportCartState extends State<ReportCart> {
  final TextEditingController _damageReportController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<DateTime> _selectedWorkDates = [];
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

  void _onWorkDatesChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      _selectedWorkDates = List<DateTime>.from(args.value);
    });
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
    final damageReport = _damageReportController.text.trim();
    final location = _locationController.text.trim();

    print("Τοποθεσία έργου: $location");
    print("Περίοδος έργου: ${_startDate != null ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}" : "-"} "
        "έως ${_endDate != null ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}" : "-"}");
    print("🛠Τύπος έργου: $_selectedProjectType");

    widget.onWorkPeriodReport();
    widget.onDamageReport();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Κλείσιμο"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("Υποβολή"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
