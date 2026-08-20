//
//  PolylineProximityResult 2.swift
//  iMapRouteGeometryKit
//
//  Created by Manoj R on 20/08/26.
//


import CoreGraphics

/// Describes the result of finding the closest point on a polyline segment.
///
/// A `PolylineProximityResult` identifies which segment of the polyline was
/// closest to the query point, how far away that segment was, and the exact
/// point on the segment that was closest.
///
/// The coordinate space is the same as the `CGPoint` values supplied to
/// `PolylineProximityAnalyzer`. For map usage, this is typically screen-space
/// coordinates.
public struct PolylineProximityResult {

    /// The index of the first point in the closest segment.
    ///
    /// The segment is represented by:
    ///
    /// `points[segmentIndex] -> points[segmentIndex + 1]`
    public let segmentIndex: Int

    /// The distance from the query point to the closest point on the segment.
    ///
    /// The unit is the same as the coordinate space used by the input
    /// `CGPoint` values. For example, when using screen coordinates, this
    /// value is measured in points.
    public let distance: CGFloat

    /// The closest point on the segment to the query point.
    ///
    /// This is the point on the actual line segment, not necessarily one of
    /// the segment's endpoints.
    public let closestPoint: CGPoint

    /// Creates a polyline proximity result.
    ///
    /// - Parameters:
    ///   - segmentIndex: The index of the first point in the closest segment.
    ///   - distance: The distance from the query point to the closest point
    ///     on the segment.
    ///   - closestPoint: The closest point on the segment to the query point.
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
