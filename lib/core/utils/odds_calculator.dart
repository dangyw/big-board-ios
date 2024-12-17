class OddsCalculator {
  /// Formats odds to a string with + prefix for positive odds
  static String formatOdds(double decimalOdds) {
    final americanOdds = decimalToAmerican(decimalOdds);
    if (americanOdds >= 0) {
      return '+$americanOdds';
    }
    return americanOdds.toString();
  }

  /// Converts decimal odds to American odds
  static int decimalToAmerican(double decimal) {
    if (decimal >= 2.0) {
      return ((decimal - 1) * 100).round();
    } else {
      return (-100 / (decimal - 1)).round();
    }
  }

  /// Calculates total parlay odds by multiplying decimal odds
  static double calculateParlayOdds(List<double> decimalOdds) {
    if (decimalOdds.isEmpty) return 1.0;
    return decimalOdds.fold(1.0, (a, b) => a * b);
  }

  /// Calculates payout based on stake and decimal odds
  static double calculatePayout(double stake, double decimalOdds) {
    return stake * decimalOdds;
  }
} 