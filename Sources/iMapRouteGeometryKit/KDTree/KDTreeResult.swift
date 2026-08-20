import CoreLocation

/// The result of a nearest-neighbor search performed by a ``KDTree``.
///
/// A `KDTreeResult` contains the model closest to the requested coordinate,
/// its position in the original model collection, and the coordinate used
/// for the nearest-neighbor comparison.
///
/// Example:
///
///     if let result = tree.nearest(to: tapCoordinate) {
///         print("Nearest model: \(result.model)")
///         print("Original index: \(result.index)")
///         print("Coordinate: \(result.coordinate)")
///     }
public struct KDTreeResult<Model> {

    /// The model identified as the nearest model to the search coordinate.
    public let model: Model

    /// The index of the nearest model in the original array supplied to
    /// the ``KDTree``.
    ///
    /// This is the model's original collection index, not its position
    /// inside the internally sorted KD-tree.
    public let index: Int

    /// The geographic coordinate of the nearest model.
    public let coordinate: CLLocationCoordinate2D

    /// Creates a KD-tree search result.
    ///
    /// - Parameters:
    ///   - model: The nearest model.
    ///   - index: The model's original index in the source collection.
    ///   - coordinate: The geographic coordinate associated with the model.
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
