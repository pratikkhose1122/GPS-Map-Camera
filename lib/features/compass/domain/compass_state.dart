class CompassState {
  final double? headingDegrees;
  final String? cardinalDirection;

  const CompassState({this.headingDegrees, this.cardinalDirection});

  CompassState copyWith({
    double? headingDegrees,
    String? cardinalDirection,
    bool clear = false,
  }) {
    if (clear) {
      return const CompassState();
    }
    return CompassState(
      headingDegrees: headingDegrees ?? this.headingDegrees,
      cardinalDirection: cardinalDirection ?? this.cardinalDirection,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompassState &&
          other.headingDegrees == headingDegrees &&
          other.cardinalDirection == cardinalDirection);

  @override
  int get hashCode => headingDegrees.hashCode ^ cardinalDirection.hashCode;
}
