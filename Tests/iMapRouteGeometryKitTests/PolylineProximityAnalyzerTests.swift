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

        guard let result else {
            XCTFail("Expected a nearest route segment")
            return
        }
        XCTAssertEqual(result.segmentIndex, 0)
        XCTAssertEqual(result.closestPoint.x, CGFloat(50), accuracy: CGFloat(0.001))
        XCTAssertEqual(result.closestPoint.y, CGFloat(0), accuracy: CGFloat(0.001))
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
