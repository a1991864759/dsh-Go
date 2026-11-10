// 设置 → 自定义界面: which chat parts start hidden, and how a switch is
// stored. The default set is the contract: the activity strip and the
// full-access pill are off out of the box.

import 'package:dsh_app/state/chat_ui_parts.dart';
import 'package:dsh_app/state/settings_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A controller that starts from a given state, without reading prefs.
class _Fixed extends SettingsController {
  _Fixed(this.initial);

  final AppSettings initial;

  @override
  AppSettings build() => initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('新装时只藏活动条和完全权限胶囊', () {
    expect(defaultHiddenUiParts, {'activityStrip', 'permissionPill'});
  });

  test('四个分组都至少有开关，且每个控件只属于一个分组', () {
    for (final group in ChatUiGroup.values) {
      expect(ChatUiPart.of(group), isNotEmpty, reason: '$group');
    }
    expect([for (final g in ChatUiGroup.values) ...ChatUiPart.of(g)], ChatUiPart.values);
  });

  test('加载完成后按存下的集合显示', () {
    final container = ProviderContainer(
      overrides: [settingsProvider.overrideWith(() => _Fixed(const AppSettings(loaded: true)))],
    );
    addTearDown(container.dispose);
    expect(container.read(uiPartHiddenProvider(ChatUiPart.activityStrip)), isFalse);
    expect(container.read(uiPartHiddenProvider(ChatUiPart.terminalPill)), isFalse);
  });

  test('加载完成前按默认值藏', () {
    final container = ProviderContainer(overrides: [settingsProvider.overrideWith(() => _Fixed(const AppSettings()))]);
    addTearDown(container.dispose);
    expect(container.read(uiPartHiddenProvider(ChatUiPart.activityStrip)), isTrue);
    expect(container.read(uiPartHiddenProvider(ChatUiPart.permissionPill)), isTrue);
    expect(container.read(uiPartHiddenProvider(ChatUiPart.terminalPill)), isFalse);
  });

  test('关掉一个开关写进 SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).setUiPartHidden('headerTitle', true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('hidden_ui_parts'), contains('headerTitle'));
  });

  test('恢复默认把整组换回默认值', () async {
    SharedPreferences.setMockInitialValues({'hidden_ui_parts': ['headerTitle', 'whaleTail']});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).setHiddenUiParts(defaultHiddenUiParts);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('hidden_ui_parts'), unorderedEquals(defaultHiddenUiParts));
  });
}
