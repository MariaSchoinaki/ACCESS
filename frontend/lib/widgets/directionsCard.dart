import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DirectionsCard extends StatelessWidget {
  final List<String> instructions;
  final int currentStep;

  const DirectionsCard({
    required this.instructions,
    required this.currentStep,
    Key? key,
  }) : super(key: key);

  Widget getDirectionIcon(String instruction) {
    instruction = instruction.toLowerCase();
    if (instruction.contains('right')) {
      return const Icon(Icons.arrow_right_alt, size: 32, color: Colors.orange);
    } else if (instruction.contains('left')) {
      return const Icon(Icons.arrow_left, size: 32, color: Colors.orange);
    } else if (instruction.contains('straight')) {
      return const Icon(Icons.arrow_upward, size: 32, color: Colors.orange);
    } else if (instruction.contains('back')) {
      return const Icon(Icons.arrow_back, size: 32, color: Colors.orange);
    }
    // default icon
    return const Icon(Icons.directions, size: 32, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 150,
      child: ListView.builder(
        itemCount: instructions.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isActive = index == currentStep;
          return Container(
            width: 250,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? theme.primaryColor : theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                BoxShadow(
                  color: AppColors.primaryAccent.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  getDirectionIcon(instructions[index]),
                  const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 180,
                  ),
                  child: Text(
                    instructions[index],
                    style: TextStyle(
                      color: isActive ? AppColors.white : theme.textTheme.bodyMedium?.color,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ],
              )

            ),
          );
        },
      ),
    );
  }
}
