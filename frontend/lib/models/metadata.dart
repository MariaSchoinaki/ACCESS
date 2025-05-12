class ParsedMetadata {
  final String? phone;
  final String? website;
  final List<OpenPeriod>? openHours;

  ParsedMetadata({
    this.phone,
    this.website,
    this.openHours,
  });
}

class OpenPeriod {
  final int openDay;
  final String openTime;
  final int closeDay;
  final String closeTime;

  OpenPeriod({
    required this.openDay,
    required this.openTime,
    required this.closeDay,
    required this.closeTime,
  });
}
