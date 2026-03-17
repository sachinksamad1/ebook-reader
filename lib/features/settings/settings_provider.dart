import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../models/user_settings.dart';
import '../../core/theme/app_theme.dart';
import '../reader/reader_settings.dart';
import '../library/library_provider.dart';

final userSettingsProvider = StreamProvider<UserSettings>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.streamUserSettings();
});

class UserSettingsNotifier extends StateNotifier<AsyncValue<UserSettings>> {
  final Ref _ref;

  UserSettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _listenToSettings();
  }

  void _listenToSettings() {
    _ref.listen<AsyncValue<UserSettings>>(userSettingsProvider, (
      previous,
      next,
    ) {
      state = next;
    }, fireImmediately: true);
  }

  Future<void> updateFontSize(double size) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(fontSize: size);
    await _saveSettings(updated);
  }

  Future<void> updateFontFamily(ReaderFontFamily family) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(fontFamily: family);
    await _saveSettings(updated);
  }

  Future<void> updateThemeMode(ReaderThemeMode mode) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(themeMode: mode);
    await _saveSettings(updated);
  }

  Future<void> _saveSettings(UserSettings settings) async {
    state = AsyncValue.data(settings);

    try {
      final service = _ref.read(firebaseServiceProvider);
      await service.updateUserSettings(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userSettingsNotifierProvider =
    StateNotifierProvider<UserSettingsNotifier, AsyncValue<UserSettings>>((
      ref,
    ) {
      return UserSettingsNotifier(ref);
    });
