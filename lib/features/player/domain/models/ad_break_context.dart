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

  AdBreakContextBuilder toBuilder() => AdBreakContextBuilder(
        maxSecondsRemaining: maxSecondsRemaining,
        positionInCurrentAdBreak: positionInCurrentAdBreak,
        totalAdsInBreakEstimate: totalAdsInBreakEstimate,
      );

  static AdBreakContextBuilder builder() => AdBreakContextBuilder();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdBreakContext &&
          other.maxSecondsRemaining == maxSecondsRemaining &&
          other.positionInCurrentAdBreak == positionInCurrentAdBreak &&
          other.totalAdsInBreakEstimate == totalAdsInBreakEstimate);

  @override
  int get hashCode => Object.hash(
        maxSecondsRemaining,
        positionInCurrentAdBreak,
        totalAdsInBreakEstimate,
      );

  @override
  String toString() =>
      'AdBreakContext{maxSecondsRemaining=$maxSecondsRemaining, positionInCurrentAdBreak=$positionInCurrentAdBreak, totalAdsInBreakEstimate=$totalAdsInBreakEstimate}';
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

  AdBreakContextBuilder maxSecondsRemaining(int val) {
    _maxSecondsRemaining = val;
    return this;
  }

  AdBreakContextBuilder positionInCurrentAdBreak(int val) {
    _positionInCurrentAdBreak = val;
    return this;
  }

  AdBreakContextBuilder totalAdsInBreakEstimate(int val) {
    _totalAdsInBreakEstimate = val;
    return this;
  }

  AdBreakContext build() => AdBreakContext(
        maxSecondsRemaining: _maxSecondsRemaining,
        positionInCurrentAdBreak: _positionInCurrentAdBreak,
        totalAdsInBreakEstimate: _totalAdsInBreakEstimate,
      );
}
