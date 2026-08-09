import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) => SharedPrefsStorageService());

enum AppUnidades { metrico, imperial }

class SettingsState {
  final ThemeMode themeMode;
  final String idioma;
  final AppUnidades unidades;
  final String huertaNombre;
  final int towerCapacity; // 12 (mini) o 24 (normal)
  /// true = leer telemetría desde Firebase RTDB (NodeMCU real)
  /// false = usar simulador local
  final bool usarHardware;

  /// ID del dispositivo físico vinculado (impreso en la torre, ej. "HS-001").
  final String deviceId;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.idioma = 'Español',
    this.unidades = AppUnidades.metrico,
    this.huertaNombre = 'Mi Huerta Viva',
    this.towerCapacity = 24,
    this.usarHardware = false,
    this.deviceId = 'HS-001',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? idioma,
    AppUnidades? unidades,
    String? huertaNombre,
    int? towerCapacity,
    bool? usarHardware,
    String? deviceId,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      idioma: idioma ?? this.idioma,
      unidades: unidades ?? this.unidades,
      huertaNombre: huertaNombre ?? this.huertaNombre,
      towerCapacity: towerCapacity ?? this.towerCapacity,
      usarHardware: usarHardware ?? this.usarHardware,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  /// Etiqueta del modelo de torre según su capacidad.
  String get towerLabel => towerCapacity == 12 ? 'Torre Mini' : 'Torre Normal';
  int get towerNiveles => towerCapacity == 12 ? 4 : 8;
  double get towerAltura => towerCapacity == 12 ? 0.95 : 1.65;

  String get unidadesLabel => unidades == AppUnidades.metrico ? '°C · Litros · cm' : '°F · Galones · in';

  bool get isImperial => unidades == AppUnidades.imperial;

  /// Formats a Celsius value, converting to Fahrenheit when unidades == imperial.
  String formatTemp(double celsius, {int decimals = 0}) {
    if (!isImperial) return '${celsius.toStringAsFixed(decimals)}°C';
    final f = celsius * 9 / 5 + 32;
    return '${f.toStringAsFixed(decimals)}°F';
  }

  /// Formats a liters value, converting to US gallons when unidades == imperial.
  String formatVolume(double liters, {int decimals = 1}) {
    if (!isImperial) return '${liters.toStringAsFixed(decimals)}L';
    final gal = liters * 0.264172;
    return '${gal.toStringAsFixed(decimals)}gal';
  }

  /// Formats a centimeters value, converting to inches when unidades == imperial.
  String formatLength(double cm, {int decimals = 0}) {
    if (!isImperial) return '${cm.toStringAsFixed(decimals)}cm';
    final inches = cm / 2.54;
    return '${inches.toStringAsFixed(decimals)}in';
  }

  /// Formats a meters value, converting to feet when unidades == imperial.
  String formatMeters(double meters, {int decimals = 2}) {
    if (!isImperial) return '${meters.toStringAsFixed(decimals)}m';
    final feet = meters * 3.28084;
    return '${feet.toStringAsFixed(decimals)}ft';
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final theme = await _storage.getString('theme_mode');
    final idioma = await _storage.getString('idioma');
    final unidades = await _storage.getString('unidades');
    final nombre = await _storage.getString('huerta_nombre');
    final tower = await _storage.getString('tower_capacity');
    final hardware = await _storage.getString('usar_hardware');
    final deviceId = await _storage.getString('device_id');

    state = state.copyWith(
      deviceId: deviceId ?? state.deviceId,
      themeMode: switch (theme) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      idioma: idioma ?? state.idioma,
      unidades: unidades == 'imperial' ? AppUnidades.imperial : AppUnidades.metrico,
      huertaNombre: nombre ?? state.huertaNombre,
      towerCapacity: tower == '12' ? 12 : 24,
      usarHardware: hardware == '1',
    );
  }

  Future<void> setTowerCapacity(int capacity) async {
    state = state.copyWith(towerCapacity: capacity);
    await _storage.setString('tower_capacity', capacity.toString());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.setString('theme_mode', mode.name);
  }

  Future<void> setIdioma(String idioma) async {
    state = state.copyWith(idioma: idioma);
    await _storage.setString('idioma', idioma);
  }

  Future<void> setUnidades(AppUnidades unidades) async {
    state = state.copyWith(unidades: unidades);
    await _storage.setString('unidades', unidades.name);
  }

  Future<void> setHuertaNombre(String nombre) async {
    state = state.copyWith(huertaNombre: nombre);
    await _storage.setString('huerta_nombre', nombre);
  }

  Future<void> setUsarHardware(bool value) async {
    state = state.copyWith(usarHardware: value);
    await _storage.setString('usar_hardware', value ? '1' : '0');
  }

  Future<void> setDeviceId(String id) async {
    state = state.copyWith(deviceId: id);
    await _storage.setString('device_id', id);
  }

  Future<void> resetAll() async {
    await _storage.remove('theme_mode');
    await _storage.remove('idioma');
    await _storage.remove('unidades');
    await _storage.remove('huerta_nombre');
    await _storage.remove('tower_capacity');
    state = const SettingsState();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.read(storageServiceProvider));
});
