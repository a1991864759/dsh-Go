// 宠物设置 → 显示思考: the switch, the 只显示 ⏵ 行 choice, and the two numbers
// that keep the line readable (how often it may change, how much of it shows).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pets/pet_prefs.dart';
import '../settings/settings_widgets.dart' show SettingsSection, SettingsSwitchTile, settingsTitleStyle;
import '../theme/theme.dart';
import '../theme/shapes.dart';

class PetThoughtSection extends ConsumerWidget {
  const PetThoughtSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = ref.watch(petPrefsProvider);
    final notifier = ref.read(petPrefsProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSection(
          children: <Widget>[
            SettingsSwitchTile(
              title: '显示思考',
              subtitle: '把当前在想的那句显示在宠物头顶；关掉只是不自动显示，长按仍能看',
              value: prefs.thought,
              onChanged: (v) => unawaited(notifier.setThought(v)),
            ),
            if (prefs.thought)
              SettingsSwitchTile(
                title: '只显示 ⏵ 概括行',
                subtitle: '只看模型自己写的那句，不显示完整推理（隐私更稳）',
                value: prefs.thoughtOnlyNarration,
                onChanged: (v) => unawaited(notifier.setThoughtOnlyNarration(v)),
              ),
          ],
        ),
        if (prefs.thought)
          SettingsSection(
            title: '节奏',
            children: <Widget>[
              _NumberRow(
                label: '换句间隔',
                value: '${prefs.thoughtSeconds} 秒',
                hint: '1–10 秒。太短会闪，太长跟不上',
                current: prefs.thoughtSeconds.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => unawaited(notifier.setThoughtSeconds(v.round())),
                scheme: scheme,
              ),
              _NumberRow(
                label: '每条字数',
                value: '${prefs.thoughtChars} 字',
                hint: '16–64 字，超出用省略号',
                current: prefs.thoughtChars.toDouble(),
                min: 16,
                max: 64,
                divisions: 12,
                onChanged: (v) => unawaited(notifier.setThoughtChars(v.round())),
                scheme: scheme,
              ),
            ],
          ),
      ],
    );
  }
}

/// A labelled slider: the current value on the right, the hint under it.
class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.current,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.scheme,
  });

  final String label;
  final String value;
  final String hint;
  final double current;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 10, AppSpace.gutter, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(label, style: settingsTitleStyle(context))),
              const SizedBox(width: 12),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: label,
            value: value,
            child: Slider(
              value: current.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              padding: EdgeInsets.zero,
              activeColor: scheme.onSurfaceVariant,
              inactiveColor: scheme.onSurface.withValues(alpha: 0.1),
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
