class OddsCalculator {
  static double usToDecimal(int usOdds) {
    if (usOdds > 0) {
      return 1 + (usOdds / 100);
    }
    return 1 + (100 / usOdds.abs());
  }

  static int decimalToUs(double decimal) {
    if (decimal >= 2) {
      return ((decimal - 1) * 100).round();
    }
    return (-100 / (decimal - 1)).round();
  }

  static int calculateParlayOdds(List<int> odds) {
    if (odds.isEmpty) return 0;
    
    final decimal = odds.fold(1.0, (acc, odd) => acc * usToDecimal(odd));
    return decimalToUs(decimal);
  }

  static String formatOdds(int odds) {
    return odds > 0 ? '+$odds' : '$odds';
  }
} 