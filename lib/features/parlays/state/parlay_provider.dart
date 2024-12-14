import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './parlay_state.dart';

class ParlayProvider extends StatelessWidget {
  final Widget child;

  const ParlayProvider({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParlayState(),
      child: child,
    );
  }
} 