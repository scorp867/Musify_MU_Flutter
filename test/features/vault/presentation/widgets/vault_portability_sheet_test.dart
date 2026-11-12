import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/features/vault/application/portability/vault_portability_cubit.dart';
import 'package:musify_mu/features/vault/domain/entities/private_playlist.dart';
import 'package:musify_mu/features/vault/domain/entities/private_track_ref.dart';
import 'package:musify_mu/features/vault/presentation/widgets/vault_portability_sheet.dart';

class MockPortabilityCubit extends VaultPortabilityCubit {
  final VaultPortabilityState initialTestState;

  MockPortabilityCubit({required this.initialTestState}) : super() {
    emit(initialTestState);
  }

  @override
  Future<void> loadPortabilityData() async {
    // Keep test state deterministic
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultPortabilitySheet Widget Tests', () {
    testWidgets('Renders header and tab switcher with Import and Export tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockCubit = MockPortabilityCubit(
        initialTestState: const VaultPortabilityLoadedState(
          spotifyPlaylists: [],
          localTracksCount: 5,
          exportablePlaylists: [],
          totalExportableTracksCount: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultPortabilitySheet(cubitOverride: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vault Portability'), findsOneWidget);
      expect(find.text('Import to Vault'), findsOneWidget);
      expect(find.text('Export to Public'), findsOneWidget);
      expect(find.text('All Device Music Files'), findsOneWidget);
      expect(find.text('5 tracks discovered on device'), findsOneWidget);
    });

    testWidgets('Tapping Export to Public tab switches view and displays sandbox empty state when 0 tracks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockCubit = MockPortabilityCubit(
        initialTestState: const VaultPortabilityLoadedState(
          spotifyPlaylists: [],
          localTracksCount: 3,
          exportablePlaylists: [],
          totalExportableTracksCount: 0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultPortabilitySheet(cubitOverride: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap export tab
      await tester.tap(find.text('Export to Public'));
      await tester.pumpAndSettle();

      expect(find.text('Option A: Restore to Public Storage'), findsOneWidget);
      expect(find.text('No Sandboxed Tracks to Export'), findsOneWidget);
      expect(find.text('No private playlists have sandbox-isolated tracks.'), findsOneWidget);
    });

    testWidgets('Export tab lists exportable playlists and Unvault All button when sandbox media exists', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now().millisecondsSinceEpoch;
      final sandboxRef = PrivateTrackRef(
        id: 'sandbox_1',
        playlistId: 'pl_sand',
        trackUri: '/storage/isolated.mp3',
        title: 'Classified Track',
        artistName: 'Secret Artist',
        albumTitle: 'Hidden Album',
        durationMs: 240000,
        sourceType: TrackSourceTypeEnum.localSandbox,
        localRelativePath: 'isolated.mp3',
        sortOrder: 0,
        addedAtEpochMs: now,
      );

      final exportablePlaylist = PrivatePlaylist(
        id: 'pl_sand',
        name: 'Hidden Masters',
        description: 'Physical vault tracks',
        totalDurationMs: 240000,
        createdAtEpochMs: now,
        updatedAtEpochMs: now,
        trackRefs: [sandboxRef],
      );

      final mockCubit = MockPortabilityCubit(
        initialTestState: VaultPortabilityLoadedState(
          spotifyPlaylists: const [],
          localTracksCount: 1,
          exportablePlaylists: [exportablePlaylist],
          totalExportableTracksCount: 1,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultPortabilitySheet(cubitOverride: mockCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export to Public'));
      await tester.pumpAndSettle();

      expect(find.text('Export All 1 Sandboxed Tracks'), findsOneWidget);
      expect(find.text('Hidden Masters'), findsOneWidget);
      expect(find.text('1 physically isolated media tracks'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
    });
  });
}
