import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';


/// Popup dialog for collecting user demographics and accessibility needs.
///
/// Features:
/// - Date of birth input via DatePicker
/// - Disability selection via dropdown
/// - Input validation with error handling
class UserInfoPopup extends StatefulWidget {
  /// Callback with validated data
  final void Function(String birthDate, String disabilityType) onSubmit;

  /// Pre-filled values for edit mode (optional)
  final String? initialBirthDate;
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

class _UserInfoPopupState extends State<UserInfoPopup> {
  late TextEditingController _birthDateController;
  late String _selectedDisability;
  String? _errorMessage;

  /// Greek accessibility options
  static const List<String> _disabilityOptions = [
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
    _birthDateController = TextEditingController(
      text: widget.initialBirthDate ?? '',
    );
    _selectedDisability = widget.initialDisability ?? _disabilityOptions.last;
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Πληροφορίες Χρήστη"),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tap to open date picker
          TextField(
            controller: _birthDateController,
            keyboardType: TextInputType.number,
            //cursorColor: AppColors.primary,
            decoration: InputDecoration(

              labelText: 'Ημερομηνία Γέννησης (DD/MM/YYYY)',
              errorText: _errorMessage,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            onTap: () => _pickDate(context),
          ),

          const SizedBox(height: 16),
          // Dropdown for disability
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedDisability,
            items: _disabilityOptions
                .map((type) => DropdownMenuItem(
              value: type,
              child: Text(type, overflow: TextOverflow.ellipsis),
            ))
                .toList(),
            onChanged: (value) => setState(() {
              _selectedDisability = value ?? _disabilityOptions.last;
            }),
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
          style: ButtonStyle(foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            return AppColors.black;
          }),
            textStyle: WidgetStateProperty.all(
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  /// Opens a date picker and updates the birth date field
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _parseDate(_birthDateController.text) ?? DateTime(now.year - 20);
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 10);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('el', 'GR'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
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

    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _birthDateController.text = formatted;
        _errorMessage = null;
      });
    }
  }

  /// Validates input and submits if all fields are valid
  void _validateAndSubmit() {
    if (_isValidDate(_birthDateController.text)) {
      widget.onSubmit(_birthDateController.text, _selectedDisability);
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = 'Μη έγκυρη ημερομηνία';
      });
    }
  }

  /// Parses a string to DateTime in DD/MM/YYYY format
  DateTime? _parseDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(date);
    } catch (_) {
      return null;
    }
  }

  /// Validates birth date format and age range (10–100 years old)
  bool _isValidDate(String date) {
    final parsedDate = _parseDate(date);
    if (parsedDate == null) return false;

    final now = DateTime.now();
    final minDate = now.subtract(const Duration(days: 365 * 100));
    final maxDate = now.subtract(const Duration(days: 365 * 10));

    return parsedDate.isAfter(minDate) && parsedDate.isBefore(maxDate);
  }
}
