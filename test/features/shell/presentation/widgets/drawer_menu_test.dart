import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify_mu/core/cache/app_cache_manager.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_refresher.dart';
import 'package:musify_mu/core/network/spotify/auth/spotify_token_store.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/data/spotify_profile_fetcher.dart';
import 'package:musify_mu/features/auth/domain/entities/spotify_user.dart';
import 'package:musify_mu/features/shell/presentation/widgets/drawer_menu.dart';
import 'package:musify_mu/features/vault/data/gesture/default_gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_sample.dart';
import 'package:musify_mu/features/vault/domain/entities/gesture_template.dart';
import 'package:musify_mu/features/vault/domain/entities/recognition_score.dart';
import 'package:musify_mu/features/vault/domain/entities/vault_result.dart';
import 'package:musify_mu/features/vault/domain/interfaces/i_gesture_recognizer.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_sensitivity_tier.dart';
import 'package:musify_mu/features/vault/domain/policies/gesture_visibility_policy.dart';
import 'package:musify_mu/features/vault/presentation/widgets/stealth_gesture_pad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTokenStore implements SpotifyTokenStore {
  @override
  void addChangeListener(void Function() listener) {}
  @override
  void removeChangeListener(void Function() listener) {}
  @override
  Future<void> saveSpDc(String spDc) async {}
  @override
  Future<String?> getSpDc() async => null;
  @override
  Future<bool> hasSpDc() async => false;
  @override
  Future<void> saveAccessToken(String token, {int lifetimeMs = 3600000}) async {}
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<bool> isAccessTokenExpired() async => true;
  @override
  Future<bool> hasValidAccessToken() async => false;
  @override
  Future<void> saveUsername(String username) async {}
  @override
  Future<String?> getUsername() async => null;
  @override
  Future<void> saveProfile({
    required String username,
    required String displayName,
    String? avatarUrl,
    String? country,
    String? product,
  }) async {}
  @override
  Future<({String username, String displayName, String? avatarUrl, String? country, String? product})?> getCachedProfile() async => null;
  @override
  Future<void> saveClientToken(String token, {int lifetimeMs = 86400000}) async {}
  @override
  Future<String?> getClientToken() async => null;
  @override
  Future<bool> isClientTokenExpired() async => false;
  @override
  Future<void> deleteClientToken() async {}
  @override
  Future<void> clearAll() async {}
}

class _FakeTokenRefresher implements SpotifyTokenRefresher {
  @override
  Future<String?> refresh() async => null;
}

class _FakeProfileFetcher implements SpotifyProfileFetcher {
  @override
  Future<SpotifyUser?> fetchProfile() async => null;
}

class FakeAuthBloc extends AuthBloc {
  FakeAuthBloc([SpotifyUser? initialUser])
      : super(
          tokenStore: _FakeTokenStore(),
          refresher: _FakeTokenRefresher(),
          profileFetcher: _FakeProfileFetcher(),
          cacheManager: AppCacheManager(),
          initialUser: initialUser,
        );
}

class FakeDrawerGestureRecognizer implements IGestureRecognizer {
  int evaluateCount = 0;
  final GestureMatchDecisionEnum decisionToReturn;

  FakeDrawerGestureRecognizer({
    this.decisionToReturn = GestureMatchDecisionEnum.matched,
  });

  @override
  Future<VaultResult<RecognitionScore>> evaluateStroke({
    required GestureSample liveStroke,
    required GestureTemplate template,
    required GestureSensitivityTierEnum sensitivityTier,
  }) async {
    evaluateCount++;
    return VaultResult.success(
      RecognitionScore(
        dollarOneScore: 0.95,
        dtwScore: 0.90,
        featureScore: 0.90,
        ensembleScore: 0.925,
        decision: decisionToReturn,
      ),
    );
  }

  @override
  Future<VaultResult<GestureTemplate>> synthesizeMasterTemplate({
    required List<GestureSample> samples,
  }) async {
    return VaultResult.success(DefaultGestureTemplate.canonicalVShape);
  }

  @override
  Future<VaultResult<void>> validateSampleConsistency({
    required List<GestureSample> samples,
  }) async {
    return const VaultResult.success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DrawerMenu Integration Tests', () {
    late FakeAuthBloc authBloc;

    Widget createTestBed({
      required Widget drawer,
      SpotifyUser? user,
    }) {
      authBloc = FakeAuthBloc(user);
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 700,
            child: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: drawer,
            ),
          ),
        ),
      );
    }

    tearDown(() {
      authBloc.close();
    });

    testWidgets(
        'DrawerMenu compiles and instantiates with const DrawerMenu() and embeds StealthGesturePad in Expanded spacer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestBed(
          drawer: const DrawerMenu(),
        ),
      );
      await tester.pump();

      // StealthGesturePad must be present
      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);

      // Verify that StealthGesturePad is wrapped in an Expanded widget
      final expandedAncestor = find.ancestor(
        of: padFinder,
        matching: find.byType(Expanded),
      );
      expect(expandedAncestor, findsWidgets);

      // Verify navigation items exist
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Equalizer'), findsOneWidget);
      expect(find.text('Connect Spotify'), findsOneWidget);
    });

    testWidgets(
        'StealthGesturePad occupies the vertical space between Equalizer and bottom item',
        (WidgetTester tester) async {
      const user = SpotifyUser(id: 'musify_user', displayName: 'Jane Doe');

      await tester.pumpWidget(
        createTestBed(
          drawer: const DrawerMenu(),
          user: user,
        ),
      );
      await tester.pump();

      final equalizerFinder = find.text('Equalizer');
      final padFinder = find.byType(StealthGesturePad);
      final logoutFinder = find.text('Log Out');

      expect(equalizerFinder, findsOneWidget);
      expect(padFinder, findsOneWidget);
      expect(logoutFinder, findsOneWidget);

      final equalizerBottom = tester.getBottomLeft(equalizerFinder).dy;
      final padTop = tester.getTopLeft(padFinder).dy;
      final padBottom = tester.getBottomLeft(padFinder).dy;
      final logoutTop = tester.getTopLeft(logoutFinder).dy;

      expect(padTop, greaterThanOrEqualTo(equalizerBottom),
          reason: 'StealthGesturePad must be below Equalizer');
      expect(logoutTop, greaterThanOrEqualTo(padBottom),
          reason: 'StealthGesturePad must be above Log Out');
    });

    testWidgets(
        'DrawerMenu correctly forwards injected parameters to StealthGesturePad',
        (WidgetTester tester) async {
      final customRecognizer = FakeDrawerGestureRecognizer();
      final customTemplate = DefaultGestureTemplate.canonicalVShape;
      bool matchedCallbackFired = false;

      await tester.pumpWidget(
        createTestBed(
          drawer: DrawerMenu(
            onVaultGestureMatched: () {
              matchedCallbackFired = true;
            },
            gestureRecognizer: customRecognizer,
            gestureTemplate: customTemplate,
            gestureSensitivityTier: GestureSensitivityTierEnum.strict92Percent,
            gestureVisibilityPolicy:
                GestureVisibilityPolicyEnum.faintDissipatingHairline,
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);

      final padWidget = tester.widget<StealthGesturePad>(padFinder);
      expect(padWidget.recognizer, equals(customRecognizer));
      expect(padWidget.activeTemplate, equals(customTemplate));
      expect(padWidget.sensitivityTier,
          equals(GestureSensitivityTierEnum.strict92Percent));
      expect(padWidget.visibilityPolicy,
          equals(GestureVisibilityPolicyEnum.faintDissipatingHairline));

      // Trigger matched callback through pad
      padWidget.onGestureMatched();
      expect(matchedCallbackFired, isTrue);
    });

    testWidgets('Drawing on DrawerMenu spacer area activates onVaultGestureMatched',
        (WidgetTester tester) async {
      bool matchedFired = false;
      final recognizer = FakeDrawerGestureRecognizer();

      await tester.pumpWidget(
        createTestBed(
          drawer: DrawerMenu(
            onVaultGestureMatched: () {
              matchedFired = true;
            },
            gestureRecognizer: recognizer,
          ),
        ),
      );
      await tester.pump();

      final padFinder = find.byType(StealthGesturePad);
      expect(padFinder, findsOneWidget);

      final padCenter = tester.getCenter(padFinder);
      final gesture = await tester.startGesture(padCenter);
      await gesture.moveBy(const Offset(30, 60));
      await gesture.moveBy(const Offset(30, -60));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(matchedFired, isTrue,
          reason: 'Drawn gesture must trigger onVaultGestureMatched');
      expect(recognizer.evaluateCount, equals(1));
    });

    testWidgets('Renders authenticated user profile vs offline mode correctly',
        (WidgetTester tester) async {
      // 1. Unauthenticated state
      await tester.pumpWidget(
        createTestBed(
          drawer: const DrawerMenu(),
          user: null,
        ),
      );
      await tester.pump();

      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Connect Spotify'), findsOneWidget);
      expect(find.byType(StealthGesturePad), findsOneWidget);

      // 2. Authenticated state
      await tester.pumpWidget(
        createTestBed(
          drawer: const DrawerMenu(),
          user: const SpotifyUser(
            id: 'alice_123',
            displayName: 'Alice Musician',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Alice Musician'), findsOneWidget);
      expect(find.text('@alice_123'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.byType(StealthGesturePad), findsOneWidget);
    });
  });
}
