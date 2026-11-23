import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../program/program_providers.dart';
import '../../program/program_settings.dart';
import '../../program/therapist_pin.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rohab_icon.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/action_area.dart';

/// Therapist plan settings, behind a 4-digit PIN.
class TherapistScreen extends ConsumerStatefulWidget {
  const TherapistScreen({super.key});

  static const pinFieldKey = Key('therapist-pin');
  static const primaryKey = Key('therapist-primary');
  static const secondaryKey = Key('therapist-secondary');
  static const wristCheckKey = Key('therapist-wrist-check');
  static Key levelKey(int? level) => Key('therapist-level-${level ?? 'auto'}');
  static Key stepKey(String id, bool up) =>
      Key('therapist-$id-${up ? 'up' : 'down'}');

  @override
  ConsumerState<TherapistScreen> createState() => _TherapistScreenState();
}

enum _Gate { setPin, confirmPin, enterPin, unlocked }

class _TherapistScreenState extends ConsumerState<TherapistScreen> {
  late _Gate _gate;
  final _pin = TextEditingController();

  /// Kept on the field after each step, so the keyboard stays open for
  /// the confirmation.
  final _pinFocus = FocusNode();
  String? _firstPin;
  String? _error;
  ProgramSettings? _draft;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _gate = ref.read(programStoreProvider).pinHash == null
        ? _Gate.setPin
        : _Gate.enterPin;
  }

  @override
  void dispose() {
    _pin.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    final pin = _pin.text;
    final store = ref.read(programStoreProvider);
    if (!TherapistPin.isValid(pin)) {
      setState(() => _error = 'Enter 4 digits.');
      return;
    }
    switch (_gate) {
      case _Gate.setPin:
        setState(() {
          _firstPin = pin;
          _gate = _Gate.confirmPin;
          _error = null;
        });
      case _Gate.confirmPin:
        if (pin != _firstPin) {
          setState(() {
            _gate = _Gate.setPin;
            _error = 'The PINs did not match. Choose a PIN again.';
          });
        } else {
          await store.savePinHash(TherapistPin.hash(pin));
          _unlock();
        }
      case _Gate.enterPin:
        if (TherapistPin.matches(pin, store.pinHash)) {
          _unlock();
        } else {
          setState(() => _error = 'That PIN is not right.');
        }
      case _Gate.unlocked:
        break;
    }
    _pin.clear();
    if (_gate != _Gate.unlocked) _pinFocus.requestFocus();
  }

  void _unlock() => setState(() {
    _gate = _Gate.unlocked;
    _error = null;
    _draft = ref.read(programSettingsProvider);
  });

  Future<void> _save() async {
    await ref.read(programSettingsProvider.notifier).save(_draft!);
    setState(() => _notice = 'Saved.');
  }

  Future<void> _resetGoal() async {
    await ref.read(programSettingsProvider.notifier).save(_draft!);
    await ref.read(programSettingsProvider.notifier).resetGoal();
    setState(
      () => _notice = "Saved. Today's goal is back to ${_draft!.startingGoal}.",
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final back = TextButton(
      key: TherapistScreen.secondaryKey,
      onPressed: () => context.go(Routes.settings),
      child: const Text('Back'),
    );

    if (_gate != _Gate.unlocked) {
      final title = switch (_gate) {
        _Gate.setPin => 'Choose a therapist PIN',
        _Gate.confirmPin => 'Enter the PIN again',
        _ => 'Therapist PIN',
      };
      return _Layout(
        secondary: back,
        primary: FilledButton(
          key: TherapistScreen.primaryKey,
          onPressed: _submitPin,
          child: Text(_gate == _Gate.enterPin ? 'Unlock' : 'Continue'),
        ),
        children: [
          Text(title, style: t.headlineMedium),
          const SizedBox(height: RohabSpace.s16),
          Text(
            _gate == _Gate.enterPin
                ? 'These settings are for the therapist or caregiver.'
                : '4 digits. It keeps the plan from being changed by '
                      'accident; it is not a password.',
            style: t.bodyLarge,
          ),
          const SizedBox(height: RohabSpace.s24),
          TextField(
            key: TherapistScreen.pinFieldKey,
            controller: _pin,
            focusNode: _pinFocus,
            obscureText: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: TherapistPin.length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: t.headlineMedium,
            onSubmitted: (_) => _submitPin(),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RohabShape.radius),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: RohabSpace.s8),
            Text(_error!, style: t.labelLarge),
          ],
        ],
      );
    }

    final d = _draft!;
    void set(ProgramSettings s) => setState(() {
      _draft = s;
      _notice = null;
    });
    return _Layout(
      // Shown next to Save, where the eye is after tapping it.
      notice: _notice,
      secondary: Row(
        children: [
          Expanded(child: back),
          Expanded(
            child: TextButton(
              onPressed: _resetGoal,
              child: const Text("Reset today's goal"),
            ),
          ),
        ],
      ),
      primary: FilledButton(
        key: TherapistScreen.primaryKey,
        onPressed: _save,
        child: const Text('Save'),
      ),
      children: [
        Text('Therapist plan', style: t.headlineMedium),
        const SizedBox(height: RohabSpace.s24),
        Text('Level', style: t.labelLarge),
        const SizedBox(height: RohabSpace.s8),
        Text('Auto uses the hand measurement.', style: t.labelMedium),
        const SizedBox(height: RohabSpace.s8),
        Row(
          children: [
            for (final level in [null, 1, 2, 3]) ...[
              if (level != null) const SizedBox(width: RohabSpace.s8),
              Expanded(
                child: _Choice(
                  key: TherapistScreen.levelKey(level),
                  label: level == null ? 'Auto' : '$level',
                  selected: d.levelOverride == level,
                  onTap: () => set(d.copyWith(levelOverride: () => level)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: RohabSpace.s16),
        const Divider(),
        _Stepper(
          id: 'goal',
          label: 'Starting daily goal',
          value: d.startingGoal,
          unit: 'reps',
          min: ProgramSettings.goalRange.min,
          max: ProgramSettings.goalRange.max,
          step: 10,
          onChanged: (v) => set(d.copyWith(startingGoal: v)),
        ),
        const Divider(),
        _Stepper(
          id: 'max',
          label: 'Highest daily goal',
          value: d.maxGoal,
          unit: 'reps',
          min: ProgramSettings.goalRange.min,
          max: ProgramSettings.goalRange.max,
          step: 10,
          onChanged: (v) => set(d.copyWith(maxGoal: v)),
        ),
        const Divider(),
        _Stepper(
          id: 'set',
          label: 'Reps per set',
          value: d.setSize,
          unit: 'reps',
          min: ProgramSettings.setRange.min,
          max: ProgramSettings.setRange.max,
          step: 1,
          onChanged: (v) => set(d.copyWith(setSize: v)),
        ),
        const Divider(),
        _Stepper(
          id: 'rest',
          label: 'Rest between sets',
          value: d.restSeconds,
          unit: 's',
          min: ProgramSettings.restRange.min,
          max: ProgramSettings.restRange.max,
          step: 15,
          onChanged: (v) => set(d.copyWith(restSeconds: v)),
        ),
        const Divider(),
        _Stepper(
          id: 'painHigh',
          label: 'Advise rest when pain before is at least',
          value: d.painHighLimit,
          unit: 'of 10',
          min: 3,
          max: 10,
          step: 1,
          onChanged: (v) => set(d.copyWith(painHighLimit: v)),
        ),
        const Divider(),
        _Stepper(
          id: 'painRise',
          label: 'Warn when pain rises by at least',
          value: d.painRiseLimit,
          unit: 'points',
          min: 1,
          max: 5,
          step: 1,
          onChanged: (v) => set(d.copyWith(painRiseLimit: v)),
        ),
        const Divider(),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Raise the goal 10% after a full day without '
                  'fatigue or more pain',
                  style: t.bodyLarge,
                ),
              ),
              Switch(
                value: d.autoProgress,
                onChanged: (v) => set(d.copyWith(autoProgress: v)),
              ),
            ],
          ),
        ),
        const Divider(),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Do not count open/close reps made by bending the wrist. '
                  'The camera can get this wrong, so it is off unless you '
                  'want it.',
                  style: t.bodyLarge,
                ),
              ),
              Switch(
                key: TherapistScreen.wristCheckKey,
                value: d.wristCheck,
                onChanged: (v) => set(d.copyWith(wristCheck: v)),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.id,
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String id;
  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget button(bool up) => SizedBox.square(
      dimension: RohabSize.touchTarget,
      child: OutlinedButton(
        key: TherapistScreen.stepKey(id, up),
        onPressed: (up ? value + step <= max : value - step >= min)
            ? () => onChanged(value + (up ? step : -step))
            : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(color: context.colors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RohabShape.radius),
          ),
        ),
        child: RohabIcon(up ? RohabIconData.add : RohabIconData.remove),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RohabSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodyLarge),
          const SizedBox(height: RohabSpace.s8),
          Row(
            children: [
              button(false),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '$value $unit',
                    textAlign: TextAlign.center,
                    style: t.labelLarge,
                  ),
                ),
              ),
              button(true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(RohabShape.radius);
    return Semantics(
      button: true,
      selected: selected,
      child: ChoiceBox(
        selected: selected,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: RohabSize.touchTarget,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: selected ? c.onAccent : c.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Layout extends StatelessWidget {
  const _Layout({
    required this.children,
    this.primary,
    this.secondary,
    this.notice,
  });

  final List<Widget> children;
  final Widget? primary;
  final Widget? secondary;
  final String? notice;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
          children: children,
        ),
      ),
      if (notice != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            RohabSpace.s24,
            RohabSpace.s16,
            RohabSpace.s24,
            0,
          ),
          child: Semantics(
            liveRegion: true,
            child: Text(notice!, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ActionArea(secondary: secondary, primary: primary),
    ],
  );
}
