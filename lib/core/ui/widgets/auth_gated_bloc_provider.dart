import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/auth/application/auth_bloc.dart';
import 'package:musify_mu/features/auth/domain/entities/auth_state.dart';

/// Provides a BLoC only when the user is [Authenticated].
///
/// Shows [placeholder] while unauthenticated. When the auth state transitions
/// to [Authenticated], calls [createBloc] with the authenticated user and
/// renders [child] underneath the new [BlocProvider].
///
/// This eliminates the repeated auth-gating + inline bloc construction
/// that previously lived in presentation widgets.
class AuthGatedBlocProvider<B extends BlocBase<Object>> extends StatelessWidget {
  /// Factory that receives the authenticated user's ID and returns a bloc.
  final B Function(String userId) createBloc;

  /// Widget shown when the user is not authenticated.
  final Widget placeholder;

  /// Widget rendered inside the [BlocProvider] when authenticated.
  final Widget child;

  const AuthGatedBlocProvider({
    super.key,
    required this.createBloc,
    required this.placeholder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return placeholder;
        }

        return BlocProvider<B>(
          create: (_) => createBloc(authState.user.id),
          child: child,
        );
      },
    );
  }
}
