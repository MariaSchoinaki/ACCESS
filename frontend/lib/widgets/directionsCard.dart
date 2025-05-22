import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/navigation_step.dart';

class DirectionsCard extends StatefulWidget {
  final List<NavigationStep> steps;
  final int currentStep;

  const DirectionsCard({
    required this.steps,
    required this.currentStep,
    Key? key,
  }) : super(key: key);

  @override
  _DirectionsCardState createState() => _DirectionsCardState();
}

class _DirectionsCardState extends State<DirectionsCard> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(DirectionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _scrollToCurrentStep();
    }
  }

  void _scrollToCurrentStep() {
    // Πλάτος κάθε item + margin (περίπου 250 + 16)
    final double offset = widget.currentStep * (250 + 16);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget getDirectionIcon(String instruction) {
    final instr = instruction.toLowerCase();
    if (instr.contains('right')) {
      return const Icon(Icons.arrow_right_alt, size: 32, color: Colors.orange);
    } else if (instr.contains('left')) {
      return const Icon(Icons.arrow_left, size: 32, color: Colors.orange);
    } else if (instr.contains('straight')) {
      return const Icon(Icons.arrow_upward, size: 32, color: Colors.orange);
    } else if (instr.contains('back')) {
      return const Icon(Icons.arrow_back, size: 32, color: Colors.orange);
    }
    return const Icon(Icons.directions, size: 32, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 150,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: widget.steps.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isActive = index == widget.currentStep;
          final step = widget.steps[index];
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
                  getDirectionIcon(step.instruction),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      step.instruction,
                      style: TextStyle(
                        color: isActive ? Colors.white : theme.textTheme.bodyMedium?.color,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
