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
  static const List<String> _disabilityOptions = [
    "Χρήση αμαξιδίου",
    "Χρήση βοηθητικού εξοπλισμού",
    "Γονείς με μωρό σε καρότσι",
    "Προβλήματα όρασης",
    "Προσωρινή κινητική δυσκολία",
    "Καμία"
  ];

  /// Initializes the state for the user information form
  ///
  /// Responsibilities:
  /// - Sets up [TextEditingController] with initial birth date value
  /// - Selects initial disability type from provided value or defaults to last option
  /// - Inherits parent widget initialization through [super.initState]
  ///
  /// Behavior:
  /// - Uses [widget.initialBirthDate] if available (can be null)
  /// - Falls back to [_disabilityOptions.last] ("Καμία" - "None") if no initial disability provided
  @override
  void initState() {
    super.initState();
    // Initialize form with existing values or defaults
    _birthDateController = TextEditingController(
        text: widget.initialBirthDate ?? ''
    );
    _selectedDisability = widget.initialDisability ?? _disabilityOptions.last;
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
      title: const Text("Πληροφορίες Χρήστη"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _birthDateController,
            decoration: InputDecoration(
              labelText: 'Ημερομηνία Γέννησης (DD/MM/YYYY)',
              errorText: _errorMessage,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[0-9/]*$')),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedDisability,
            items: _disabilityOptions.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (value) => setState(() => _selectedDisability = value ?? _disabilityOptions.last),
            decoration: const InputDecoration(
              labelText: "Είδος Αναπηρίας",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _validateAndSubmit,
          child: const Text("Αποθήκευση"),
        ),
      ],
    );
  }

  /// Validates and submits the user information form
  ///
  /// Workflow:
  /// 1. Validates date format using [_isValidDate]
  /// 2. On valid date:
  ///    - Clears any existing error messages
  ///    - Calls parent [onSubmit] callback with form data
  ///    - Closes the dialog using [Navigator.pop]
  /// 3. On invalid date:
  ///    - Sets error message to Greek "Μη έγκυρη ημερομηνία" ("Invalid date")
  ///    - Triggers UI rebuild to display error
  ///
  /// Note: Validation includes both format checks and age range verification (10-100 years)
  void _validateAndSubmit() {
    if (_isValidDate(_birthDateController.text)) {
      widget.onSubmit(_birthDateController.text, _selectedDisability);
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = 'Μη έγκυρη ημερομηνία');
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