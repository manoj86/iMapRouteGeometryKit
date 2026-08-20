import CoreGraphics

/// Performs map-independent proximity calculations against an ordered
/// polyline represented by `CGPoint` values.
///
/// The analyzer works in screen space and deliberately has no dependency
/// on MapKit, Google Maps, or any application-specific model.
///
/// Apple Maps and Google Maps can convert their geographic route coordinates
/// into screen-space points and then use this analyzer to determine how
/// close a user's tap is to the actual route line.
///
/// The analyzer is typically used after a `KDTree` identifies a nearby
/// route coordinate. Instead of checking the entire route, only the
/// neighboring segments around that coordinate are inspected.
///
/// Example:
///
///     let analyzer = PolylineProximityAnalyzer(points: routePoints)
///
///     if let result = analyzer.hit(
///         at: tapPoint,
///         around: nearestPointIndex,
///         tolerance: 20
///     ) {
///         print("Route tapped at \(result.closestPoint)")
///     }
public struct PolylineProximityAnalyzer {

    private let points: [CGPoint]

    /// Creates a proximity analyzer for an ordered polyline.
    ///
    /// - Parameter points: The ordered screen-space points representing
    ///   the route polyline.
    ///
    /// - Note:
    ///   At least two points are required to form a route segment.
    public init(points: [CGPoint]) {
        self.points = points
    }

    /// Finds the route segment closest to a query point within a local
    /// neighborhood of the known nearest route point.
    ///
    /// This method does not search the entire polyline. Instead, it examines
    /// the segments surrounding `nearestPointIndex`.
    ///
    /// For example, with a `searchRadius` of `2`, the analyzer checks the
    /// segments around the nearby point:
    ///
    ///     P[index - 2] → P[index - 1]
    ///     P[index - 1] → P[index]
    ///     P[index]     → P[index + 1]
    ///     P[index + 1] → P[index + 2]
    ///
    /// For each candidate segment, the closest point on the line segment to
    /// the query point is calculated. The segment with the smallest distance
    /// is returned.
    ///
    /// - Parameters:
    ///   - point: The query point, normally the user's map tap in screen space.
    ///   - nearestPointIndex: The index of a nearby route point, typically
    ///     obtained from a `KDTree` search.
    ///   - searchRadius: The number of route points to inspect on either side
    ///     of the nearby point. Defaults to `2`.
    ///
    /// - Returns: A `PolylineProximityResult` describing the closest segment,
    ///   its distance from the query point, and the closest point on that
    ///   segment. Returns `nil` when there are insufficient points or the
    ///   index is invalid.
    ///
    /// - Complexity:
    ///   The search examines only a small number of neighboring segments,
    ///   making it independent of the total route size when the search radius
    ///   is fixed.
    public func nearestSegment(
        to point: CGPoint,
        around nearestPointIndex: Int,
        searchRadius: Int = 2
    ) -> PolylineProximityResult? {

        guard points.count >= 2,
              points.indices.contains(nearestPointIndex) else {
            return nil
        }

        let radius = max(0, searchRadius)

        let startIndex = max(
            0,
            nearestPointIndex - radius
        )

        let endIndex = min(
            points.count - 2,
            nearestPointIndex + radius
        )

        guard startIndex <= endIndex else {
            return nil
        }

        var bestResult: PolylineProximityResult?

        for segmentIndex in startIndex...endIndex {

            let result = distanceToSegment(
                point: point,
                start: points[segmentIndex],
                end: points[segmentIndex + 1]
            )

            let candidate = PolylineProximityResult(
                segmentIndex: segmentIndex,
                distance: result.distance,
                closestPoint: result.closestPoint
            )

            if bestResult == nil ||
                candidate.distance < bestResult!.distance {

                bestResult = candidate
            }
        }

        return bestResult
    }

    /// Determines whether a query point is close enough to the route to be
    /// considered a route hit.
    ///
    /// The analyzer first finds the closest neighboring segment and then
    /// compares its distance to the supplied screen-space tolerance.
    ///
    /// - Parameters:
    ///   - point: The query point, normally the user's map tap in screen space.
    ///   - nearestPointIndex: The index of a nearby route point, typically
    ///     obtained from a `KDTree` search.
    ///   - tolerance: The maximum allowed distance from the route, measured
    ///     in screen-space points.
    ///   - searchRadius: The number of route points to inspect on either side
    ///     of the nearby point. Defaults to `2`.
    ///
    /// - Returns: A `PolylineProximityResult` when the closest segment is
    ///   within the specified tolerance; otherwise `nil`.
    ///
    /// Example:
    ///
    ///     if let result = analyzer.hit(
    ///         at: tapPoint,
    ///         around: nearestPointIndex,
    ///         tolerance: 20
    ///     ) {
    ///         // The user tapped close enough to the route.
    ///     }
    public func hit(
        at point: CGPoint,
        around nearestPointIndex: Int,
        tolerance: CGFloat,
        searchRadius: Int = 2
    ) -> PolylineProximityResult? {

        guard tolerance >= 0,
              let result = nearestSegment(
                  to: point,
                  around: nearestPointIndex,
                  searchRadius: searchRadius
              ) else {
            return nil
        }

        return result.distance <= tolerance
            ? result
            : nil
    }
}

// MARK: - Geometry

private extension PolylineProximityAnalyzer {

    /// Calculates the shortest distance between a point and a line segment.
    ///
    /// The calculation projects the query point onto the infinite line formed
    /// by the segment and then clamps the projection to the segment's endpoints.
    ///
    /// This ensures that the returned closest point always lies between
    /// `start` and `end`.
    ///
    /// - Parameters:
    ///   - point: The query point.
    ///   - start: The starting point of the line segment.
    ///   - end: The ending point of the line segment.
    ///
    /// - Returns: The shortest distance from the query point to the segment
    ///   and the corresponding closest point on that segment.
    func distanceToSegment(
        point: CGPoint,
        start: CGPoint,
        end: CGPoint
    ) -> (
        distance: CGFloat,
        closestPoint: CGPoint
    ) {

        let dx = end.x - start.x
        let dy = end.y - start.y

        let lengthSquared = (dx * dx) + (dy * dy)

        // Handle a zero-length segment.
        if lengthSquared == 0 {

            let distance = hypot(
                point.x - start.x,
                point.y - start.y
            )

            return (
                distance: distance,
                closestPoint: start
            )
        }

        var projection = (
            ((point.x - start.x) * dx) +
            ((point.y - start.y) * dy)
        ) / lengthSquared

        // Clamp the projection so the closest point remains
        // within the actual segment rather than the infinite line.
        projection = max(
            0,
            min(1, projection)
        )

        let closestPoint = CGPoint(
            x: start.x + (projection * dx),
            y: start.y + (projection * dy)
        )

        let distance = hypot(
            point.x - closestPoint.x,
            point.y - closestPoint.y
        )

        return (
            distance: distance,
            closestPoint: closestPoint
        )
    }
}
