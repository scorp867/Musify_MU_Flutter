---
title: "auth_gated_bloc_provider.dart"
path: "lib/core/ui/widgets/auth_gated_bloc_provider.dart"
type: "source-code"
tags: [code, dart, musify-mu, core, ui]
lines: 46
incoming_dependencies: 1
outgoing_dependencies: 2
---

# auth_gated_bloc_provider.dart

> Source File: `[lib/core/ui/widgets/auth_gated_bloc_provider.dart](file:///c:/Users/Admin/Musify_MU/lib/core/ui/widgets/auth_gated_bloc_provider.dart)`
> Layer: `lib/core/ui/widgets`

## Executive Summary
`auth_gated_bloc_provider.dart` is an essential file in `lib/core/ui/widgets` providing definitions for Top-level functions/constants.

## Dependency Mapping

### Outgoing Dependencies (What this file imports)
| Target File | Layer | Reference |
|-------------|-------|-----------|
| `auth_bloc.dart` | `lib/features/auth/application` | [[04-Reference/lib/features/auth/application/auth_bloc|auth_bloc.dart]] |
| `auth_state.dart` | `lib/features/auth/domain/entities` | [[04-Reference/lib/features/auth/domain/entities/auth_state|auth_state.dart]] |

### Incoming Dependencies (What imports this file)
| Dependent File | Layer | Reference |
|----------------|-------|-----------|
| `main_screen.dart` | `lib/features/shell/presentation` | [[04-Reference/lib/features/shell/presentation/main_screen|main_screen.dart]] |

## Declarations & API Breakdown

This file contains top-level functions or standalone variables.

## State & Data Flow Analysis
- **Execution Context**: Executed within Flutter's main UI thread or background worker depending on usage.
- **Data Flow**: Stateless utility or coordinated service invocation.

## Gotchas, Edge Cases & Technical Debt
> [!WARNING] Architectural Gotcha
> Follows standard Dart sound null-safety and unidirectional BLoC event-to-state conventions.

## Implementation Highlight
```dart
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
// ... [remaining code in source file] ...
```
