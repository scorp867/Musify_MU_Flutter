// 1:1 replica of com.spotify.player.model.AdBreakContext

class AdBreakContext {
  static const AdBreakContext empty = AdBreakContext(
    maxSecondsRemaining: 0,
    positionInCurrentAdBreak: 0,
    totalAdsInBreakEstimate: 0,
  );

  final int maxSecondsRemaining;
  final int positionInCurrentAdBreak;
  final int totalAdsInBreakEstimate;

  const AdBreakContext({
    this.maxSecondsRemaining = 0,
    this.positionInCurrentAdBreak = 0,
    this.totalAdsInBreakEstimate = 0,
  });

  static AdBreakContextBuilder builder() => AdBreakContextBuilder();

  AdBreakContextBuilder toBuilder() => AdBreakContextBuilder(
        maxSecondsRemaining: maxSecondsRemaining,
        positionInCurrentAdBreak: positionInCurrentAdBreak,
        totalAdsInBreakEstimate: totalAdsInBreakEstimate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdBreakContext &&
          other.maxSecondsRemaining == maxSecondsRemaining &&
          other.positionInCurrentAdBreak == positionInCurrentAdBreak &&
          other.totalAdsInBreakEstimate == totalAdsInBreakEstimate);

  @override
  int get hashCode {
    var result = (maxSecondsRemaining ^ (maxSecondsRemaining >> 32)) ^ 1000003;
    result = (result * 1000003) ^ (positionInCurrentAdBreak ^ (positionInCurrentAdBreak >> 32));
    result = (result * 1000003) ^ (totalAdsInBreakEstimate ^ (totalAdsInBreakEstimate >> 32));
    return result;
  }

  @override
  String toString() =>
      'AdBreakContext{maxSecondsRemaining=$maxSecondsRemaining, '
      'positionInCurrentAdBreak=$positionInCurrentAdBreak, '
      'totalAdsInBreakEstimate=$totalAdsInBreakEstimate}';
}

class AdBreakContextBuilder {
  int _maxSecondsRemaining;
  int _positionInCurrentAdBreak;
  int _totalAdsInBreakEstimate;

  AdBreakContextBuilder({
    int maxSecondsRemaining = 0,
    int positionInCurrentAdBreak = 0,
    int totalAdsInBreakEstimate = 0,
  })  : _maxSecondsRemaining = maxSecondsRemaining,
        _positionInCurrentAdBreak = positionInCurrentAdBreak,
        _totalAdsInBreakEstimate = totalAdsInBreakEstimate;

  AdBreakContextBuilder maxSecondsRemaining(int j) {
    _maxSecondsRemaining = j;
    return this;
  }

  AdBreakContextBuilder positionInCurrentAdBreak(int j) {
    _positionInCurrentAdBreak = j;
    return this;
  }

  AdBreakContextBuilder totalAdsInBreakEstimate(int j) {
    _totalAdsInBreakEstimate = j;
    return this;
  }

  AdBreakContext build() => AdBreakContext(
        maxSecondsRemaining: _maxSecondsRemaining,
        positionInCurrentAdBreak: _positionInCurrentAdBreak,
        totalAdsInBreakEstimate: _totalAdsInBreakEstimate,
      );
}
