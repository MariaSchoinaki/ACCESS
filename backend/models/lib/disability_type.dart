enum DisabilityType {
  mobility,
  visual,
  hearing,
  cognitive,
  none,
  unknown,
}

DisabilityType disabilityTypeFromGreek(String greek) {
  if (greek == 'Χρήση αμαξιδίου' || greek == 'Χρήση βοηθητικού εξοπλισμού' || greek == 'Γονείς με μωρό σε καρότσι' || greek == 'Προσωρινή κινητική δυσκολία') {
    return DisabilityType.mobility;
  } else if (greek == 'Προβλήματα όρασης') {
    return DisabilityType.visual;
  } else if (greek == 'Καμία') {
    return DisabilityType.none;
  } else {
    return DisabilityType.unknown;
  }
}

// --- Helper for disability type weighting ---
double getDisabilityWeight(DisabilityType type) {
  switch (type) {
    case DisabilityType.mobility:
      return 0.5;
    case DisabilityType.visual:
      return 0.1;
    case DisabilityType.none:
      return 0.05;
    default:
      return 0.5;
  }
}

// --- Score color helper ---
String determineColorAsHexString(double score) {
  if (score > 0.7) return 'FF00FF00'; // green
  if (score >= 0.4) return 'FFFFFF00'; // yellow
  return 'FFFF0000'; // red
}