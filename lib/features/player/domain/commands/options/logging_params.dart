// 1:1 replica of com.spotify.player.model.command.options.LoggingParams

class LoggingParams {
  static final LoggingParams empty = builder().build();

  final String? commandId;
  final int? commandInitiatedTime;
  final int? commandReceivedTime;
  final Set<String> pageInstanceIds;
  final Set<String> interactionIds;

  const LoggingParams({
    this.commandId,
    this.commandInitiatedTime,
    this.commandReceivedTime,
    this.pageInstanceIds = const <String>{},
    this.interactionIds = const <String>{},
  });

  static LoggingParamsBuilder builder() => LoggingParamsBuilder();

  String? get interactionId =>
      interactionIds.isNotEmpty ? interactionIds.first : null;

  String? get pageInstanceId =>
      pageInstanceIds.isNotEmpty ? pageInstanceIds.first : null;

  LoggingParamsBuilder toBuilder() => LoggingParamsBuilder(
        commandId: commandId,
        commandInitiatedTime: commandInitiatedTime,
        commandReceivedTime: commandReceivedTime,
        pageInstanceIds: pageInstanceIds,
        interactionIds: interactionIds,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoggingParams &&
          other.commandId == commandId &&
          other.commandInitiatedTime == commandInitiatedTime &&
          other.commandReceivedTime == commandReceivedTime &&
          other.pageInstanceIds.length == pageInstanceIds.length &&
          other.pageInstanceIds.containsAll(pageInstanceIds) &&
          other.interactionIds.length == interactionIds.length &&
          other.interactionIds.containsAll(interactionIds));

  @override
  int get hashCode => Object.hash(
        commandId,
        commandInitiatedTime,
        commandReceivedTime,
        Object.hashAll(pageInstanceIds),
        Object.hashAll(interactionIds),
      );

  @override
  String toString() =>
      'LoggingParams{commandId=$commandId, commandInitiatedTime=$commandInitiatedTime, commandReceivedTime=$commandReceivedTime, pageInstanceIds=$pageInstanceIds, interactionIds=$interactionIds}';
}

class LoggingParamsBuilder {
  String? _commandId;
  int? _commandInitiatedTime;
  int? _commandReceivedTime;
  Set<String> _pageInstanceIds;
  Set<String> _interactionIds;

  LoggingParamsBuilder({
    String? commandId,
    int? commandInitiatedTime,
    int? commandReceivedTime,
    Set<String> pageInstanceIds = const <String>{},
    Set<String> interactionIds = const <String>{},
  })  : _commandId = commandId,
        _commandInitiatedTime = commandInitiatedTime,
        _commandReceivedTime = commandReceivedTime,
        _pageInstanceIds = Set<String>.from(pageInstanceIds),
        _interactionIds = Set<String>.from(interactionIds);

  LoggingParamsBuilder commandId(String val) {
    _commandId = val;
    return this;
  }

  LoggingParamsBuilder commandInitiatedTime(int val) {
    _commandInitiatedTime = val;
    return this;
  }

  LoggingParamsBuilder commandReceivedTime(int val) {
    _commandReceivedTime = val;
    return this;
  }

  LoggingParamsBuilder interactionId(String val) {
    _interactionIds = {val};
    return this;
  }

  LoggingParamsBuilder interactionIds(Set<String> val) {
    _interactionIds = Set<String>.from(val);
    return this;
  }

  LoggingParamsBuilder pageInstanceId(String val) {
    _pageInstanceIds = {val};
    return this;
  }

  LoggingParamsBuilder pageInstanceIds(Set<String> val) {
    _pageInstanceIds = Set<String>.from(val);
    return this;
  }

  LoggingParams build() => LoggingParams(
        commandId: _commandId,
        commandInitiatedTime: _commandInitiatedTime,
        commandReceivedTime: _commandReceivedTime,
        pageInstanceIds: Set<String>.unmodifiable(_pageInstanceIds),
        interactionIds: Set<String>.unmodifiable(_interactionIds),
      );
}
