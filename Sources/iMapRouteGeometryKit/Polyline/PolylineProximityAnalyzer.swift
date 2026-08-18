import CoreGraphics

/// Performs map-independent proximity calculations against an ordered
/// polyline represented by CGPoint values.
///
/// The analyzer deliberately has no dependency on MapKit or Google Maps.
/// Apple Maps and Google Maps can both convert their route coordinates into
/// screen-space CGPoint values before using this type.
public struct PolylineProximityAnalyzer {

    private let points: [CGPoint]

    public init(points: [CGPoint]) {
        self.points = points
    }

    /// Finds the closest segment around a known nearby route point.
    ///
    /// - Parameters:
    ///   - point: Query point, normally the user's map tap in screen space.
    ///   - nearestPointIndex: Index returned by KDTree.
    ///   - searchRadius: Number of route points inspected on either side.
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

    /// Returns a route hit when the closest nearby segment is within the
    /// supplied screen-space tolerance.
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

    private func distanceToSegment(
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
