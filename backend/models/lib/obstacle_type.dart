/// Types of obstacles a user can report.
enum ObstacleType {
  brokenSidewalk,
  illegalParking,
  stairs,
  noRamp,
  roadworks,
  other,
  unknown,
}

/// Maps Greek or English string to ObstacleType enum.
ObstacleType obstacleTypeFromGreek(String greek) {
  if (greek == 'Σπασμένο Πεζοδρόμιο') {
    return ObstacleType.brokenSidewalk;
  } else if (greek == 'Παράνομη Στάθμευση') {
    return ObstacleType.illegalParking;
  } else if (greek == 'Σκαλιά') {
    return ObstacleType.stairs;
  } else if (greek == 'Χωρίς Ράμπα') {
    return ObstacleType.noRamp;
  } else if (greek == 'Έργα Δήμου') {
    return ObstacleType.roadworks;
  } else if (greek == 'Άλλο') {
    return ObstacleType.other;
  } else {
    return ObstacleType.unknown;
  }
}

/// Helper to get the weighting/impact of an obstacle type (like getDisabilityWeight).
double getObstacleWeight(ObstacleType type) {
  switch (type) {
    case ObstacleType.brokenSidewalk:
      return 0.3;
    case ObstacleType.illegalParking:
      return 0.15;
    case ObstacleType.stairs:
      return 0.1;
    case ObstacleType.noRamp:
      return 0.2;
    case ObstacleType.roadworks:
      return 0.25;
    case ObstacleType.other:
      return 0.35;
    case ObstacleType.unknown:
    default:
      return 0.4; // Default/medium impact
  }
}

/// Helper to get color hex for obstacle impact score (same naming style as disability).
String getObstacleImpactColor(double score) {
  if (score > 0.7) return 'FF00FF00'; // green
  if (score >= 0.4) return 'FFFFFF00'; // yellow
  return 'FFFF0000'; // red
}

/// Shortcut to get impact value directly from string (mirrors impactFromObstacleTypeString)
double getObstacleImpactFromString(String value) =>
    getObstacleWeight(obstacleTypeFromGreek(value));
