import 'package:flutter/material.dart';

class UserInfoPopup extends StatefulWidget {
  final void Function(String birthDate, String disabilityType) onSubmit;

  const UserInfoPopup({super.key, required this.onSubmit});

  @override
  State<UserInfoPopup> createState() => _UserInfoPopupState();
}

class _UserInfoPopupState extends State<UserInfoPopup> {
  final TextEditingController _birthDateController = TextEditingController();
  String _selectedDisability = "None";

  final List<String> disabilityOptions = [
    "Mobility impairment",
    "Use of mobility aid",
    "Vision impairment",
    "None",
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Please fill the bellow."),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _birthDateController,
            decoration: const InputDecoration(
              labelText: 'Date of birth (DD/MM/YYYY)',
            ),
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
              labelText: "Disability kind",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onSubmit(_birthDateController.text, _selectedDisability);
            Navigator.of(context).pop();
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
