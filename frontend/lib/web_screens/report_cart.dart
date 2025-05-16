import 'package:flutter/material.dart';

class ReportCart extends StatelessWidget {
  final VoidCallback onWorkPeriodReport;
  final VoidCallback onDamageReport;

  const ReportCart({
    Key? key,
    required this.onWorkPeriodReport,
    required this.onDamageReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Επιλέξτε τι θέλετε να αναφέρετε:",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          /// Πλαίσιο 1
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              onWorkPeriodReport();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: Row(
                children: const [
                  Icon(Icons.access_time),
                  SizedBox(width: 10),
                  Text("Αναφορά εργατικής περιόδου"),
                ],
              ),
            ),
          ),

          /// Πλαίσιο 2
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              onDamageReport();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning),
                  SizedBox(width: 10),
                  Text("Αναφορά βλάβης"),
                ],
              ),
            ),
          ),

          /// Εδώ μπορείς να γράψεις παρακάτω ό,τι θέλεις
          const SizedBox(height: 10),
          Text(
            ".",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Κλείσιμο"),
            ),
          ),
        ],
      ),
    );
  }
}
