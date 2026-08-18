import XCTest
import CoreLocation
@testable import iMapRouteGeometryKit

final class KDTreeTests: XCTestCase {

    private struct RoutePoint: Equatable {
        let id: Int
        let latitude: Double
        let longitude: Double
    }

    private func coordinate(
        _ model: RoutePoint
    ) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: model.latitude,
            longitude: model.longitude
        )
    }

    func testNearestReturnsOriginalModelIndex() {
        let models = [
            RoutePoint(id: 10, latitude: 10.0, longitude: 10.0),
            RoutePoint(id: 20, latitude: 10.0, longitude: 10.1),
            RoutePoint(id: 30, latitude: 10.0, longitude: 10.2),
            RoutePoint(id: 40, latitude: 10.0, longitude: 10.3)
        ]

        let tree = KDTree(
            models: models,
            coordinateProvider: coordinate
        )

        let result = tree.nearest(
            to: CLLocationCoordinate2D(
                latitude: 10.0,
                longitude: 10.21
            )
        )

        XCTAssertEqual(result?.model.id, 30)
        XCTAssertEqual(result?.index, 2)
    }

    func testRadiusRejectsDistantPoint() {
        let models = [
            RoutePoint(id: 1, latitude: 10.0, longitude: 10.0)
        ]

        let tree = KDTree(
            models: models,
            coordinateProvider: coordinate
        )

        let result = tree.nearest(
            to: CLLocationCoordinate2D(
                latitude: 11.0,
                longitude: 11.0
            ),
            within: 10
        )

        XCTAssertNil(result)
    }

    func testUpdatePreservesOriginalOrderForIndex() {
        let initial = [
            RoutePoint(id: 1, latitude: 10.0, longitude: 10.0),
            RoutePoint(id: 2, latitude: 10.0, longitude: 10.1)
        ]

        let tree = KDTree(
            models: initial,
            coordinateProvider: coordinate
        )

        tree.update(with: [
            RoutePoint(id: 3, latitude: 10.0, longitude: 10.2)
        ])

        let result = tree.nearest(
            to: CLLocationCoordinate2D(
                latitude: 10.0,
                longitude: 10.19
            )
        )

        XCTAssertEqual(result?.model.id, 3)
        XCTAssertEqual(result?.index, 2)
    }
}
