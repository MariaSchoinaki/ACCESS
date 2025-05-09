enum DisabilityType {
  mobility,
  visual,
  hearing,
  cognitive,
  unknown
}

double getDisabilityWeight(DisabilityType type) {
  switch (type) {
    case DisabilityType.mobility: return 0.9;
    case DisabilityType.visual: return 0.7;
    case DisabilityType.hearing: return 0.3;
    case DisabilityType.cognitive: return 0.6;
    case DisabilityType.unknown: return 0.5;
    default: return 0.5;
  }
}

String determineColorAsHexString(double score) {
  if (score > 0.7) return "FF00FF00";
  if (score >= 0.4) return "FFFFFF00";
  return "FFFF0000";
}