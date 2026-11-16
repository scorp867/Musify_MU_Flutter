import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/app/theme/app_theme.dart';
import 'package:musify_mu/features/connect/domain/models/connect_group_device.dart';
import 'package:musify_mu/features/connect/domain/models/connect_volume_state.dart';
import 'package:musify_mu/features/connect/domain/models/device_type.dart';
import 'package:musify_mu/features/connect/domain/models/grouping_status.dart';
import 'package:musify_mu/features/connect/presentation/widgets/group_device_tile.dart';

ConnectGroupDevice _groupMember({
  required String id,
  required String name,
  GroupingStatus status = GroupingStatus.grouped,
  bool removable = true,
  bool removalDissolvesGroup = false,
  double? volume = 0.5,
}) {
  return ConnectGroupDevice(
    identifiers: GroupDeviceIdentifiers(
      groupDeviceIdentifier: id,
      localIdentifier: 'local-$id',
      connectStateIdentifier: id,
    ),
    name: name,
    deviceType: DeviceType.speaker,
    modelDisplayName: 'Nest Audio',
    capabilities: GroupDeviceCapabilities(
      removable: removable,
      removalDissolvesGroup: removalDissolvesGroup,
    ),
    groupingStatus: status,
    volume: switch (volume) {
      final v? => GroupDeviceVolume(volume: v, volumeSteps: 24),
      null => null,
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GroupDeviceTile', () {
    testWidgets('renders grouped member volume slider and step controls', (
      tester,
    ) async {
      final changedVolumes = <double>[];
      final stepDirections = <int>[];

      final member = _groupMember(
        id: 'spk-a',
        name: 'Dining Speaker',
        status: GroupingStatus.grouped,
        volume: 0.40,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: GroupDeviceTile(
                  groupDevice: member,
                  groupVolume: GroupDeviceVolume(volume: 0.60, volumeSteps: 24),
                  onVolumeChanged: changedVolumes.add,
                  onStepVolume: stepDirections.add,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dining Speaker'), findsOneWidget);
      expect(find.text('In group'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('group_step_up_spk-a')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('group_step_down_spk-a')));
      await tester.pump();
      expect(stepDirections, <int>[1, -1]);

      await tester.drag(find.byType(Slider), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(changedVolumes, isNotEmpty);
    });

    testWidgets('shows "Stop group playback?" confirmation when removalDissolvesGroup is true', (
      tester,
    ) async {
      var removeCalls = 0;
      final hostMember = _groupMember(
        id: 'spk-host',
        name: 'Hallway Speaker',
        status: GroupingStatus.grouped,
        removable: true,
        removalDissolvesGroup: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: GroupDeviceTile(
              groupDevice: hostMember,
              onRemoveFromGroup: () => removeCalls++,
            ),
          ),
        ),
      );

      // Tap remove -> opens modal dialog; "Keep playing" cancels
      await tester.tap(
        find.byKey(const ValueKey<String>('group_remove_spk-host')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Stop group playback?'), findsOneWidget);
      expect(
        find.text(
          'Removing Hallway Speaker will stop playback on all grouped devices.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Keep playing'));
      await tester.pumpAndSettle();
      expect(removeCalls, 0);

      // Tap remove again -> "End group" confirms removal
      await tester.tap(
        find.byKey(const ValueKey<String>('group_remove_spk-host')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('End group'));
      await tester.pumpAndSettle();
      expect(removeCalls, 1);
    });

    testWidgets('handles groupable add, direct non-dissolving remove, connecting, and unknown statuses', (
      tester,
    ) async {
      var addCalls = 0;
      var removeCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              children: [
                GroupDeviceTile(
                  groupDevice: _groupMember(
                    id: 'g-1',
                    name: 'Patio',
                    status: GroupingStatus.groupable,
                    volume: null,
                  ),
                  onAddToGroup: () => addCalls++,
                ),
                GroupDeviceTile(
                  groupDevice: _groupMember(
                    id: 'g-2',
                    name: 'Office',
                    status: GroupingStatus.grouped,
                    removalDissolvesGroup: false,
                  ),
                  onRemoveFromGroup: () => removeCalls++,
                ),
                GroupDeviceTile(
                  groupDevice: _groupMember(
                    id: 'g-3',
                    name: 'Bedroom',
                    status: GroupingStatus.connecting,
                    volume: null,
                  ),
                ),
                GroupDeviceTile(
                  groupDevice: _groupMember(
                    id: 'g-4',
                    name: 'Den',
                    status: GroupingStatus.unknown,
                    volume: null,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Available to group'), findsOneWidget);
      expect(find.text('Connecting...'), findsOneWidget);
      expect(find.text('Nest Audio'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('group_add_g-1')));
      await tester.pump();
      expect(addCalls, 1);

      await tester.tap(find.byKey(const ValueKey<String>('group_remove_g-2')));
      await tester.pump();
      expect(removeCalls, 1);
    });

    testWidgets('does not invoke onRemoveFromGroup if unmounted while dialog is open', (
      tester,
    ) async {
      final showTile = ValueNotifier<bool>(true);
      var removeCalls = 0;
      addTearDown(showTile.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: showTile,
              builder: (context, visible, _) {
                if (!visible) {
                  return const SizedBox.shrink();
                }
                return GroupDeviceTile(
                  groupDevice: _groupMember(
                    id: 'spk-host',
                    name: 'Hallway Speaker',
                    status: GroupingStatus.grouped,
                    removable: true,
                    removalDissolvesGroup: true,
                  ),
                  onRemoveFromGroup: () => removeCalls++,
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('group_remove_spk-host')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Stop group playback?'), findsOneWidget);

      showTile.value = false;
      await tester.pump();
      expect(find.byType(GroupDeviceTile), findsNothing);
      expect(find.text('End group'), findsOneWidget);

      await tester.tap(find.text('End group'));
      await tester.pumpAndSettle();
      expect(removeCalls, 0);
    });

    testWidgets('didUpdateWidget resets drag state when member id changes or status leaves grouped', (
      tester,
    ) async {
      final memberNotifier = ValueNotifier<ConnectGroupDevice>(
        _groupMember(
          id: 'spk-a',
          name: 'Dining Speaker',
          status: GroupingStatus.grouped,
          volume: 0.25,
        ),
      );
      addTearDown(memberNotifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: ValueListenableBuilder<ConnectGroupDevice>(
                  valueListenable: memberNotifier,
                  builder: (context, member, _) {
                    return GroupDeviceTile(
                      groupDevice: member,
                      onVolumeChanged: (_) {},
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final sliderFinder = find.byType(Slider);
      final gesture1 = await tester.startGesture(tester.getCenter(sliderFinder));
      await tester.pump();
      await gesture1.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.55));

      memberNotifier.value = _groupMember(
        id: 'spk-a',
        name: 'Dining Speaker',
        status: GroupingStatus.connecting,
        volume: null,
      );
      await tester.pump();
      expect(find.byType(Slider), findsNothing);

      await gesture1.up();
      await tester.pump();

      memberNotifier.value = _groupMember(
        id: 'spk-a',
        name: 'Dining Speaker',
        status: GroupingStatus.grouped,
        volume: 0.25,
      );
      await tester.pump();
      expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.25, 0.02));
      expect(find.text('25%'), findsOneWidget);

      final gesture2 = await tester.startGesture(tester.getCenter(sliderFinder));
      await tester.pump();
      await gesture2.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.55));

      memberNotifier.value = _groupMember(
        id: 'spk-b',
        name: 'Kitchen Speaker',
        status: GroupingStatus.grouped,
        volume: 0.35,
      );
      await tester.pump();
      expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.35, 0.02));
      expect(find.text('35%'), findsOneWidget);

      await gesture2.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'resets drag state when effectiveVolume becomes null mid-drag while still grouped',
      (tester) async {
        final memberNotifier = ValueNotifier<ConnectGroupDevice>(
          _groupMember(
            id: 'spk-a',
            name: 'Dining Speaker',
            status: GroupingStatus.grouped,
            volume: 0.25,
          ),
        );
        final groupVolumeNotifier = ValueNotifier<GroupDeviceVolume?>(
          GroupDeviceVolume(volume: 0.25, volumeSteps: 24),
        );
        addTearDown(() {
          memberNotifier.dispose();
          groupVolumeNotifier.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: ValueListenableBuilder<ConnectGroupDevice>(
                    valueListenable: memberNotifier,
                    builder: (context, member, _) {
                      return ValueListenableBuilder<GroupDeviceVolume?>(
                        valueListenable: groupVolumeNotifier,
                        builder: (context, groupVol, _) {
                          return GroupDeviceTile(
                            groupDevice: member,
                            groupVolume: groupVol,
                            onVolumeChanged: (_) {},
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.55));

        // Both groupVolume and groupDevice.volume drop to null while still grouped.
        groupVolumeNotifier.value = null;
        memberNotifier.value = _groupMember(
          id: 'spk-a',
          name: 'Dining Speaker',
          status: GroupingStatus.grouped,
          volume: null,
        );
        await tester.pump();
        expect(find.byType(Slider), findsNothing);

        await gesture.up();
        await tester.pump();

        // Volume recovers at 0.30; must display 30%, not stale drag value.
        groupVolumeNotifier.value = GroupDeviceVolume(
          volume: 0.30,
          volumeSteps: 24,
        );
        await tester.pump();
        expect(find.byType(Slider), findsOneWidget);
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
        expect(find.text('30%'), findsOneWidget);
      },
    );

    testWidgets(
      'preserves active drag across groupVolume null fallback when groupDevice.volume remains non-null',
      (tester) async {
        final memberNotifier = ValueNotifier<ConnectGroupDevice>(
          _groupMember(
            id: 'spk-a',
            name: 'Dining Speaker',
            status: GroupingStatus.grouped,
            volume: 0.40,
          ),
        );
        final groupVolumeNotifier = ValueNotifier<GroupDeviceVolume?>(
          GroupDeviceVolume(volume: 0.25, volumeSteps: 24),
        );
        addTearDown(() {
          memberNotifier.dispose();
          groupVolumeNotifier.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: ValueListenableBuilder<ConnectGroupDevice>(
                    valueListenable: memberNotifier,
                    builder: (context, member, _) {
                      return ValueListenableBuilder<GroupDeviceVolume?>(
                        valueListenable: groupVolumeNotifier,
                        builder: (context, groupVol, _) {
                          return GroupDeviceTile(
                            groupDevice: member,
                            groupVolume: groupVol,
                            onVolumeChanged: (_) {},
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump();
        final draggingValue = tester.widget<Slider>(sliderFinder).value;
        expect(draggingValue, greaterThan(0.55));

        // groupVolume override disappears, falling back to groupDevice.volume (0.40).
        groupVolumeNotifier.value = null;
        await tester.pump();
        expect(find.byType(Slider), findsOneWidget);
        expect(
          tester.widget<Slider>(sliderFinder).value,
          closeTo(draggingValue, 0.001),
        );

        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.40, 0.02));
        expect(find.text('40%'), findsOneWidget);
      },
    );

    testWidgets(
      'preserves active drag when isPending toggles mid-drag',
      (tester) async {
        final pendingNotifier = ValueNotifier<bool>(false);
        final changedVolumes = <double>[];
        addTearDown(pendingNotifier.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: pendingNotifier,
                    builder: (context, pending, _) {
                      return GroupDeviceTile(
                        groupDevice: _groupMember(
                          id: 'spk-a',
                          name: 'Dining Speaker',
                          status: GroupingStatus.grouped,
                          volume: 0.25,
                        ),
                        isPending: pending,
                        onVolumeChanged: changedVolumes.add,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump();
        final draggingValue = tester.widget<Slider>(sliderFinder).value;
        expect(draggingValue, greaterThan(0.55));

        pendingNotifier.value = true;
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester.widget<Slider>(sliderFinder).value,
          closeTo(draggingValue, 0.001),
        );

        pendingNotifier.value = false;
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          tester.widget<Slider>(sliderFinder).value,
          closeTo(draggingValue, 0.001),
        );

        final countBeforeEnd = changedVolumes.length;
        await gesture.up();
        await tester.pumpAndSettle();
        expect(changedVolumes.length, greaterThan(countBeforeEnd));
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.25, 0.02));
        expect(find.text('25%'), findsOneWidget);
      },
    );

    testWidgets(
      'clears drag state when onVolumeChanged becomes null mid-drag and restores live volume',
      (tester) async {
        final memberNotifier = ValueNotifier<ConnectGroupDevice>(
          _groupMember(
            id: 'spk-a',
            name: 'Dining Speaker',
            status: GroupingStatus.grouped,
            volume: 0.25,
          ),
        );
        final canEditVolumeNotifier = ValueNotifier<bool>(true);
        addTearDown(() {
          memberNotifier.dispose();
          canEditVolumeNotifier.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: ValueListenableBuilder<ConnectGroupDevice>(
                    valueListenable: memberNotifier,
                    builder: (context, member, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: canEditVolumeNotifier,
                        builder: (context, canEdit, _) {
                          return GroupDeviceTile(
                            groupDevice: member,
                            onVolumeChanged: canEdit ? (_) {} : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.55));

        canEditVolumeNotifier.value = false;
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).onChanged, isNull);
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.25, 0.02));

        await gesture.up();
        await tester.pump();

        memberNotifier.value = _groupMember(
          id: 'spk-a',
          name: 'Dining Speaker',
          status: GroupingStatus.grouped,
          volume: 0.30,
        );
        canEditVolumeNotifier.value = true;
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).onChanged, isNotNull);
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
        expect(find.text('30%'), findsOneWidget);
      },
    );

    testWidgets(
      'keeps Slider mounted and completes drag cleanly when onStepVolume toggles mid-drag',
      (tester) async {
        final memberNotifier = ValueNotifier<ConnectGroupDevice>(
          _groupMember(
            id: 'spk-a',
            name: 'Dining Speaker',
            status: GroupingStatus.grouped,
            volume: 0.25,
          ),
        );
        final stepEnabledNotifier = ValueNotifier<bool>(true);
        final changedVolumes = <double>[];
        addTearDown(() {
          memberNotifier.dispose();
          stepEnabledNotifier.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: ValueListenableBuilder<ConnectGroupDevice>(
                    valueListenable: memberNotifier,
                    builder: (context, member, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: stepEnabledNotifier,
                        builder: (context, stepEnabled, _) {
                          return GroupDeviceTile(
                            groupDevice: member,
                            onVolumeChanged: changedVolumes.add,
                            onStepVolume: stepEnabled ? (_) {} : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        final initialSliderState = tester.state(sliderFinder);

        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(80, 0));
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.50));

        stepEnabledNotifier.value = false;
        await tester.pump();
        expect(
          find.byKey(const ValueKey<String>('group_step_up_spk-a')),
          findsNothing,
        );
        expect(identical(tester.state(sliderFinder), initialSliderState), isTrue);

        memberNotifier.value = _groupMember(
          id: 'spk-a',
          name: 'Dining Speaker',
          status: GroupingStatus.grouped,
          volume: 0.30,
        );
        final countBeforeEnd = changedVolumes.length;
        await gesture.up();
        await tester.pumpAndSettle();
        expect(changedVolumes.length, greaterThan(countBeforeEnd));
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
        expect(find.text('30%'), findsOneWidget);
      },
    );

    testWidgets(
      'clears drag state if groupingStatus leaves grouped even while groupVolume remains non-null',
      (tester) async {
        final statusNotifier = ValueNotifier<GroupingStatus>(
          GroupingStatus.grouped,
        );
        final groupVolumeNotifier = ValueNotifier<GroupDeviceVolume?>(
          GroupDeviceVolume(volume: 0.25, volumeSteps: 24),
        );
        addTearDown(() {
          statusNotifier.dispose();
          groupVolumeNotifier.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: ValueListenableBuilder<GroupingStatus>(
                    valueListenable: statusNotifier,
                    builder: (context, status, _) {
                      return ValueListenableBuilder<GroupDeviceVolume?>(
                        valueListenable: groupVolumeNotifier,
                        builder: (context, groupVol, _) {
                          return GroupDeviceTile(
                            groupDevice: _groupMember(
                              id: 'spk-a',
                              name: 'Dining Speaker',
                              status: status,
                              volume: null,
                            ),
                            groupVolume: groupVol,
                            onVolumeChanged: (_) {},
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final sliderFinder = find.byType(Slider);
        final gesture = await tester.startGesture(tester.getCenter(sliderFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, greaterThan(0.55));

        statusNotifier.value = GroupingStatus.groupable;
        await tester.pump();
        expect(find.byType(Slider), findsNothing);

        await gesture.up();
        await tester.pump();

        groupVolumeNotifier.value = GroupDeviceVolume(
          volume: 0.30,
          volumeSteps: 24,
        );
        statusNotifier.value = GroupingStatus.grouped;
        await tester.pump();
        expect(tester.widget<Slider>(sliderFinder).value, closeTo(0.30, 0.02));
        expect(find.text('30%'), findsOneWidget);
      },
    );
  });
}
