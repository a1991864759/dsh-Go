// 设置 → 自定义界面: the activity strip and the full-access pill are off out
// of the box; switching them back on brings them back. The harness only
// pre-seeds the hidden set — everything else is the real ChatScreen.

import 'package:dsh_app/state/chat_state.dart';
import 'package:dsh_app/state/chat_ui_parts.dart';
import 'package:dsh_app/state/session_modes.dart';
import 'package:dsh_app/state/settings_state.dart';
import 'package:dsh_app/ui/chat/chat_screen.dart';
import 'package:dsh_app/ui/chat/widgets/activity_strip.dart';
import 'package:dsh_app/ui/chat/widgets/permission_pill.dart' show PermissionPill, StripRiskChip;
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

const _risky = SessionModes(preset: 'danger-full-access');

Future<void> _pump(WidgetTester tester, ChatHarness harness, ChatState state) async {
  usePhoneView(tester);
  mockClipboard(tester);
  await tester.pumpWidget(
    testApp(
      const ChatScreen(),
      overrides: [
        ...harness.overrides,
        sessionModesProvider.overrideWith((ref, id) => _risky),
      ],
    ),
  );
  await pumpFrames(tester);
}

ChatHarness _harness(Set<String> hidden, ChatState state) =>
    ChatHarness(session: 's1', states: {'s1': state}, settings: AppSettings(loaded: true, apiKey: testKey, hiddenUiParts: hidden));

void main() {
  testWidgets('默认：生成中不画活动条', (tester) async {
    const state = ChatState(running: true, autoApprove: false, loading: false);
    await _pump(tester, _harness(defaultHiddenUiParts, state), state);
    expect(find.byType(ActivityStrip), findsNothing);
    expect(find.byType(PermissionPill), findsNothing);
  });

  testWidgets('两个开关都打开：活动条与完全权限胶囊都回来', (tester) async {
    const state = ChatState(running: true, autoApprove: false, loading: false);
    await _pump(tester, _harness(const {}, state), state);
    expect(find.byType(ActivityStrip), findsOneWidget);
    // While it generates the permission lives in the strip's row, not above the composer.
    expect(find.byType(StripRiskChip), findsOneWidget);
  });
}
