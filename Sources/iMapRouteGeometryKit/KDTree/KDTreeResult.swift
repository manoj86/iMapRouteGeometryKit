import CoreLocation

/// Result returned by a KD-tree nearest-neighbor search.
public struct KDTreeResult<Model> {

    public let model: Model
    public let index: Int
    public let coordinate: CLLocationCoordinate2D

    public init(
        model: Model,
        index: Int,
        coordinate: CLLocationCoordinate2D
    ) {
        self.model = model
        self.index = index
        self.coordinate = coordinate
    }
}
