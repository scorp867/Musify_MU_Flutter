// 1:1 replica of com.spotify.player.model.command.SignalCommand

import 'command.dart';
import 'options/command_options.dart';
import 'options/logging_params.dart';

class SignalCommand implements Command {
  static const String endpointName = 'signal';

  final String signalId;
  final String? parameters;
  final CommandOptions? options;
  final LoggingParams? loggingParams;

  const SignalCommand({
    required this.signalId,
    this.parameters,
    this.options,
    this.loggingParams,
  });

  static SignalCommand create(String signalId) =>
      builder().signalId(signalId).build();

  static SignalCommandBuilder builder() => SignalCommandBuilder();

  SignalCommandBuilder toBuilder() => SignalCommandBuilder(
        signalId: signalId,
        parameters: parameters,
        options: options,
        loggingParams: loggingParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalCommand &&
          other.signalId == signalId &&
          other.parameters == parameters &&
          other.options == options &&
          other.loggingParams == loggingParams);

  @override
  int get hashCode => Object.hash(signalId, parameters, options, loggingParams);

  @override
  String toString() =>
      'SignalCommand{signalId=$signalId, parameters=$parameters, options=$options, loggingParams=$loggingParams}';
}

class SignalCommandBuilder {
  String? _signalId;
  String? _parameters;
  CommandOptions? _options;
  LoggingParams? _loggingParams;

  SignalCommandBuilder({
    String? signalId,
    String? parameters,
    CommandOptions? options,
    LoggingParams? loggingParams,
  })  : _signalId = signalId,
        _parameters = parameters,
        _options = options,
        _loggingParams = loggingParams;

  SignalCommandBuilder signalId(String val) {
    _signalId = val;
    return this;
  }

  SignalCommandBuilder parameters(String val) {
    _parameters = val;
    return this;
  }

  SignalCommandBuilder options(CommandOptions val) {
    _options = val;
    return this;
  }

  SignalCommandBuilder loggingParams(LoggingParams val) {
    _loggingParams = val;
    return this;
  }

  SignalCommand build() {
    if (_signalId == null) {
      throw StateError('Missing required properties: signalId');
    }
    return SignalCommand(
      signalId: _signalId!,
      parameters: _parameters,
      options: _options,
      loggingParams: _loggingParams,
    );
  }
}
