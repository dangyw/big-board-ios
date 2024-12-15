class PickHelper {
  final String pickId;  // e.g., "123-spread-home"
  
  const PickHelper(this.pickId);
  
  String get gameId => _parts[0];     // Returns "123"
  String get betType => _parts[1];    // Returns "spread"
  String get team => _parts[2];       // Returns "home"
  bool get isHome => team == 'home';  // Returns true/false
  
  List<String> get _parts => pickId.split('-');  // Same splitting logic
}
