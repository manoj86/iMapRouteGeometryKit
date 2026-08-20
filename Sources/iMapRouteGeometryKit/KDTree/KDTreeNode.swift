import CoreLocation

/// A node in a two-dimensional KD-tree.
///
/// Each node stores a model and its geographic coordinate, along with
/// references to the left and right child nodes.
///
/// The `axis` determines which coordinate dimension is used to partition
/// the tree at this node:
///
/// - `0`: Latitude
/// - `1`: Longitude
///
/// Nodes are normally created internally by `KDTree` while building the tree.
/// Applications generally do not need to create `KDTreeNode` instances directly.
public final class KDTreeNode<Model> {

    /// The model stored at this node.
    public let model: Model

    /// The geographic coordinate associated with the model.
    public let coordinate: CLLocationCoordinate2D

    /// The coordinate axis used to partition this node's subtree.
    ///
    /// - `0`: Latitude
    /// - `1`: Longitude
    public let axis: Int

    /// The left child node.
    ///
    /// Nodes in this subtree contain values on the lower side of the
    /// node's splitting axis.
    public var left: KDTreeNode<Model>?

    /// The right child node.
    ///
    /// Nodes in this subtree contain values on the higher side of the
    /// node's splitting axis.
    public var right: KDTreeNode<Model>?

    /// Creates a KD-tree node.
    ///
    /// - Parameters:
    ///   - model: The model stored by the node.
    ///   - coordinate: The geographic coordinate associated with the model.
    ///   - axis: The coordinate axis used to partition this node.
    ///     Use `0` for latitude and `1` for longitude.
    ///
    /// - Note:
    ///   `KDTree` normally creates and manages nodes internally, so most
    ///   applications should use `KDTree` rather than constructing nodes directly.
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
