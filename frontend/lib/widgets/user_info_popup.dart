import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


class UserInfoPopup extends StatefulWidget {
  final void Function(String birthDate, String disabilityType) onSubmit;

  const UserInfoPopup({super.key, required this.onSubmit});

  @override
  _UserInfoPopupState createState() => _UserInfoPopupState();
}

class _UserInfoPopupState extends State<UserInfoPopup> {
  final TextEditingController _birthDateController = TextEditingController();
  String _selectedDisability = "Καμία";

  final List<String> disabilityOptions = [
    "Κινητική δυσκολία",
    "Χρήση βοηθήματος κίνησης",
    "Πρόβλημα όρασης",
    "Καμία",
  ];

  String? _errorMessage;

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
              errorText: _errorMessage, // Εμφάνιση του λάθους αν υπάρχει
            ),
            keyboardType: TextInputType.text,
            inputFormatters: [
              // Επιτρέπει μόνο την είσοδο της ημερομηνίας σε format DD/MM/YYYY
              FilteringTextInputFormatter.allow(RegExp(r'^[0-9/]*$')),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDisability,
            items: disabilityOptions.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDisability = value);
              }
            },
            decoration: const InputDecoration(
              labelText: "Είδος Αναπηρίας",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Ελέγχουμε την ημερομηνία για εγκυρότητα πριν καλέσουμε το onSubmit
            if (_isValidDate(_birthDateController.text)) {
              setState(() {
                _errorMessage = null; // Καθαρίζουμε το λάθος
              });
              widget.onSubmit(_birthDateController.text, _selectedDisability);
              Navigator.of(context).pop();
            } else {
              setState(() {
                _errorMessage = 'Η ημερομηνία δεν είναι έγκυρη';
              });
            }
          },
          child: const Text("Αποθήκευση"),
        ),
      ],
    );
  }

  // Συνάρτηση ελέγχου εγκυρότητας ημερομηνίας
  bool _isValidDate(String date) {
    try {
      // Προσπαθούμε να μετατρέψουμε την ημερομηνία από το format DD/MM/YYYY
      final format = DateFormat('dd/MM/yyyy');
      final parsedDate = format.parseStrict(date); // Θα πετάξει σφάλμα αν είναι άκυρο

      // Ελέγχουμε αν η ημερομηνία είναι εντός των επιτρεπτών ορίων
      final now = DateTime.now();
      final minDate = now.subtract(Duration(days: 365 * 100)); // 100 χρόνια πριν
      final maxDate = now.subtract(Duration(days: 365 * 10)); // 10 χρόνια πριν

      return parsedDate.isAfter(minDate) && parsedDate.isBefore(maxDate);
    } catch (e) {
      return false; // Αν υπάρχει οποιοδήποτε σφάλμα, η ημερομηνία είναι άκυρη
    }
  }
}
