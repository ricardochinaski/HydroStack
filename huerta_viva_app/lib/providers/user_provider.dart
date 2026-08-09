import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

final userModeProvider = StateNotifierProvider<UserModeNotifier, AppMode>((ref) {
  return UserModeNotifier();
});

class UserModeNotifier extends StateNotifier<AppMode> {
  UserModeNotifier() : super(AppMode.basic);

  void setMode(AppMode mode) {
    state = mode;
  }

  String get modeLabel => modeLabelOf(state);
}

String modeLabelOf(AppMode mode) {
  switch (mode) {
    case AppMode.basic:
      return 'BASIC';
    case AppMode.eco:
      return 'ECO';
    case AppMode.pro:
      return 'PRO';
  }
}

/// Icono vectorial por modelo de hardware.
IconData modeIcon(AppMode mode) {
  switch (mode) {
    case AppMode.basic:
      return Icons.sync_rounded;
    case AppMode.eco:
      return Icons.eco_rounded;
    case AppMode.pro:
      return Icons.bolt_rounded;
  }
}
