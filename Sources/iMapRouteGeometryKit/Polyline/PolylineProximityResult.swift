import CoreGraphics

/// Describes the closest point found on a polyline segment.
public struct PolylineProximityResult {

    /// Index of the first point in the closest segment.
    ///
    /// The segment is `segmentIndex -> segmentIndex + 1`.
    public let segmentIndex: Int

    /// Distance from the query point to the closest point on the segment.
    /// The unit is the same as the input CGPoint coordinate space.
    public let distance: CGFloat

    /// Closest point on the segment to the query point.
    public let closestPoint: CGPoint

    public init(
        segmentIndex: Int,
        distance: CGFloat,
        closestPoint: CGPoint
    ) {
        self.segmentIndex = segmentIndex
        self.distance = distance
        self.closestPoint = closestPoint
    }
}
