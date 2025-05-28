import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// WaveformPainter is a custom painter designed to draw a dynamic
/// sound level visualization, typically used in a voice input interface.
/// It creates a series of vertical bars whose heights animate based on
/// an incoming sound level, providing visual feedback to the user.
class WaveformPainter extends CustomPainter {
  /// The target sound level that the bars should animate towards.
  final double targetSoundLevel;
  /// A boolean indicating whether the app is currently listening for speech.
  final bool isListening;
  /// Internal state to smoothly animate the current sound level.
  /// This value will gradually approach the targetSoundLevel.
  final double currentLevel;

  /// A list of colors for each individual bar in the waveform.
  final List<Color> barColors = [
    AppColors.primaryAccent.shade200,
    AppColors.primaryAccent.shade600,
    AppColors.primaryAccent.shade100,
    AppColors.primaryAccent.shade400,
  ];


  /// Constructor for the WaveformPainter, taking listening state and target sound level.
  WaveformPainter({required this.isListening,
      required this.currentLevel,
      required this.targetSoundLevel});

  @override
  /// The paint method is called whenever the CustomPaint widget needs to be redrawn.
  void paint(Canvas canvas, Size size) {
    /// Calculate the width of each individual bar.
    final barWidth = size.width / 30;
    /// The maximum height a bar can reach, which is the height of the canvas.
    final maxBarHeight = size.height;
    /// The spacing between each bar, set equal to the barWidth for visual balance.
    final spacing = barWidth; // Same as barWidth for nice spacing.
    /// Calculate the total width occupied by all 4 bars and their 3 spaces.
    final totalWidth = 4 * barWidth + 3 * spacing; // 4 bars + 3 spaces.
    /// Calculate the starting X position to center the waveform on the canvas.
    final startX = (size.width - totalWidth) / 2;

    /// Apply smoothing to the current level, making it "glide" towards the targetSoundLevel.
    /// The 0.1 is a smoothing factor (smaller value means smoother but slower animation).
    final smoothedLevel = currentLevel + (targetSoundLevel - currentLevel) * 0.1;
    //_currentLevel += (targetSoundLevel - _currentLevel) * 0.1;

    // Loop through to draw each of the 4 bars.
    for (int i = 0; i < 4; i++) {
      /// Create a Paint object for drawing each bar.
      final paint = Paint()
        ..color = barColors[i].withOpacity(0.7) // Set color with some transparency.
        ..style = PaintingStyle.fill; // Fill the rectangle.

      /// Calculate the X position for the current bar.
      final x = startX + i * (barWidth + spacing);
      /// Calculate the height factor for the bar.
      /// If listening, it's based on _currentLevel, otherwise it's a static low value.
      /// The `((_currentLevel * 10) - i).clamp(0.2, 1.0)` is a specific logic to make bars
      /// react differently based on their index, creating a wave-like effect.
      final heightFactor = isListening ? ((smoothedLevel * 10) - i).clamp(0.2, 1.0) : 0.2;
      /// Calculate the actual height of the bar.
      final barHeight = maxBarHeight * heightFactor;
      /// Define the rectangle for the current bar.
      /// `maxBarHeight - barHeight` ensures the bar draws from the bottom up.
      final rect = Rect.fromLTWH(x, maxBarHeight - barHeight, barWidth, barHeight);
      // Draw the rounded rectangle for the bar.
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
    }
  }

  @override
  /// shouldRepaint determines if the painter needs to be redrawn.
  /// It returns true if the targetSoundLevel or isListening state has changed.
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.currentLevel != currentLevel ||
        oldDelegate.targetSoundLevel != targetSoundLevel
        || oldDelegate.isListening != isListening;
  }
}
