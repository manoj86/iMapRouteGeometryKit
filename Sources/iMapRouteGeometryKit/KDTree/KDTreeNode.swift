import CoreLocation

/// A node in a two-dimensional KD-tree.
public final class KDTreeNode<Model> {

    public let model: Model
    public let coordinate: CLLocationCoordinate2D
    public let axis: Int

    public var left: KDTreeNode<Model>?
    public var right: KDTreeNode<Model>?

    init(
        model: Model,
        coordinate: CLLocationCoordinate2D,
        axis: Int
    ) {
        self.model = model
        self.coordinate = coordinate
        self.axis = axis
    }
}
