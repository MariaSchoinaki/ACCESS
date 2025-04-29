import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Dialog for collecting user demographic and accessibility information
///
/// Handles:
/// - Birth date input validation
/// - Disability type selection
/// - Data persistence between sessions
class UserInfoPopup extends StatefulWidget {
  /// Callback for submitting validated form data
  ///
  /// Parameters:
  /// - [birthDate] : Validated date string in DD/MM/YYYY format
  /// - [disabilityType] : Selected accessibility need from predefined options
  final void Function(String birthDate, String disabilityType) onSubmit;

  /// Initial birth date value for edit mode (optional)
  final String? initialBirthDate;

  /// Initial disability type for edit mode (optional)
  final String? initialDisability;

  const UserInfoPopup({
    super.key,
    required this.onSubmit,
    this.initialBirthDate,
    this.initialDisability,
  });

  @override
  _UserInfoPopupState createState() => _UserInfoPopupState();
}

/// Manages state for user information dialog
///
/// Maintains:
/// - Text editing controller for date input
/// - Selected disability type
/// - Validation error messages
class _UserInfoPopupState extends State<UserInfoPopup> {
  late final TextEditingController _birthDateController;
  late String _selectedDisability;
  String? _errorMessage;

  /// Available accessibility options with Greek/English translations
  ///
  /// Options:
  /// - "Χρήση αμαξιδίου" : Wheelchair user
  /// - "Χρήση βοηθητικού εξοπλισμού" : Mobility aid user (crutches, walker)
  /// - "Γονείς με μωρό σε καρότσι" : Parent with stroller
  /// - "Προβλήματα όρασης" : Visual impairment
  /// - "Προσωρινή κινητική δυσκολία" : Temporary mobility limitation
  /// - "Καμία" : No accessibility needs
  static const List<String> disabilityOptions = [
    "Χρήση αμαξιδίου",
    "Χρήση βοηθητικού εξοπλισμού",
    "Γονείς με μωρό σε καρότσι",
    "Προβλήματα όρασης",
    "Προσωρινή κινητική δυσκολία",
    "Καμία"
  ];

  @override
  void initState() {
    super.initState();
    // Initialize form with existing values or defaults
    _birthDateController = TextEditingController(
        text: widget.initialBirthDate ?? ''
    );
    _selectedDisability = widget.initialDisability ?? disabilityOptions.last;
  }

  /// Builds dialog components with validation-aware UI
  ///
  /// Returns:
  /// [AlertDialog] containing:
  /// - Date input field with format restrictions
  /// - Expandable disability type dropdown
  /// - Dynamic error messages
  /// - Submission button with validation
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Παρακαλώ συμπλήρωσε τα παρακάτω"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _birthDateController,
            decoration: InputDecoration(
              labelText: 'Ημερομηνία Γέννησης (DD/MM/YYYY)',
              errorText: _errorMessage,
            ),
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[0-9/]*$')),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedDisability,
            items: disabilityOptions.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDisability = value);
              }
            },
            decoration: const InputDecoration(
              labelText: "Είδος Αναπηρίας",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _handleSubmission,
          child: const Text("Αποθήκευση"),
        ),
      ],
    );
  }

  /// Validates and submits form data
  ///
  /// Workflow:
  /// 1. Checks date format validity
  /// 2. Verifies age range (10-100 years)
  /// 3. Updates error state or submits valid data
  void _handleSubmission() {
    if (_isValidDate(_birthDateController.text)) {
      setState(() => _errorMessage = null);
      widget.onSubmit(_birthDateController.text, _selectedDisability);
      Navigator.of(context).pop();
    } else {
      setState(() => _errorMessage = 'Η ημερομηνία δεν είναι έγκυρη');
    }
  }

  /// Validates birth date against format and age constraints
  ///
  /// Requirements:
  /// - Strict DD/MM/YYYY format
  /// - Birth date between 10-100 years ago
  ///
  /// Returns:
  /// [true] if valid, [false] otherwise
  bool _isValidDate(String date) {
    try {
      final format = DateFormat('dd/MM/yyyy');
      final parsedDate = format.parseStrict(date);
      final now = DateTime.now();
      final minDate = now.subtract(const Duration(days: 365 * 100));
      final maxDate = now.subtract(const Duration(days: 365 * 10));

      return parsedDate.isAfter(minDate) && parsedDate.isBefore(maxDate);
    } catch (e) {
      return false;
    }
  }
}