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

    func testNearestKeepsCorrectIndexForDuplicateCoordinates() {
        let models = [
            RoutePoint(id: 1, latitude: 10.0, longitude: 10.0),
            RoutePoint(id: 2, latitude: 10.0, longitude: 10.0)
        ]
        let tree = KDTree(
            models: models,
            coordinateProvider: coordinate
        )

        let result = tree.nearest(
            to: CLLocationCoordinate2D(latitude: 10.0, longitude: 10.0)
        )

        guard let result else {
            XCTFail("Expected a nearest coordinate")
            return
        }
        XCTAssertEqual(models[result.index].id, result.model.id)
    }

    func testRepeatedIncrementalUpdatesKeepLatestRoutePointSelectable() {
        let tree = KDTree(
            models: [RoutePoint(id: 0, latitude: 10.0, longitude: 10.0)],
            coordinateProvider: coordinate
        )
        for id in 1..<200 {
            tree.update(with: [
                RoutePoint(
                    id: id,
                    latitude: 10.0 + Double(id) * 0.0001,
                    longitude: 10.0
                )
            ])
        }

        let latest = CLLocationCoordinate2D(
            latitude: 10.0 + 199.0 * 0.0001,
            longitude: 10.0
        )
        let result = tree.nearest(to: latest, within: 1)

        XCTAssertEqual(tree.count, 200)
        XCTAssertEqual(result?.model.id, 199)
        XCTAssertEqual(result?.index, 199)
        XCTAssertNil(
            tree.nearest(
                to: CLLocationCoordinate2D(latitude: 11.0, longitude: 11.0),
                within: 1
            )
        )
    }
}
