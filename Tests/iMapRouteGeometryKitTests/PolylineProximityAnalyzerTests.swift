import XCTest
import CoreGraphics
@testable import iMapRouteGeometryKit

final class PolylineProximityAnalyzerTests: XCTestCase {

    func testTapNearSegmentIsDetectedEvenWhenFarFromVertices() {
        let analyzer = PolylineProximityAnalyzer(
            points: [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 100, y: 0),
                CGPoint(x: 200, y: 0)
            ]
        )

        let result = analyzer.hit(
            at: CGPoint(x: 50, y: 8),
            around: 0,
            tolerance: 10,
            searchRadius: 1
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.segmentIndex, 0)
        XCTAssertEqual(result?.closestPoint.x, 50, accuracy: 0.001)
        XCTAssertEqual(result?.closestPoint.y, 0, accuracy: 0.001)
    }

    func testTapFarFromPolylineIsRejected() {
        let analyzer = PolylineProximityAnalyzer(
            points: [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 100, y: 0)
            ]
        )

        let result = analyzer.hit(
            at: CGPoint(x: 50, y: 25),
            around: 0,
            tolerance: 10
        )

        XCTAssertNil(result)
    }

    func testNearestSegmentChecksBothSides() {
        let analyzer = PolylineProximityAnalyzer(
            points: [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 100, y: 0),
                CGPoint(x: 200, y: 100)
            ]
        )

        let result = analyzer.nearestSegment(
            to: CGPoint(x: 105, y: 4),
            around: 1,
            searchRadius: 1
        )

        XCTAssertEqual(result?.segmentIndex, 1)
    }
}
