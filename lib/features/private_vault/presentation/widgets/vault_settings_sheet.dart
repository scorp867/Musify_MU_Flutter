import 'package:flutter/material.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_settings.dart';
import 'package:musify_mu/features/private_vault/presentation/screens/private_vault_settings_screen.dart';

/// Legacy navigation entrypoint routing to the dedicated [PrivateVaultSettingsScreen].
class VaultSettingsSheet {
  const VaultSettingsSheet._();

  static Future<void> show(BuildContext context, VaultSettings settings) {
    return Navigator.of(context).push(PrivateVaultSettingsScreen.route());
  }
}
