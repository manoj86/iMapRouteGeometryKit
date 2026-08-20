import CoreLocation

/// A generic two-dimensional KD-tree for efficiently searching map-route coordinates.
///
/// `KDTree` can store any model type. The caller provides a coordinate provider
/// that tells the tree how to obtain a `CLLocationCoordinate2D` from each model.
///
/// The tree is useful for efficiently finding the model closest to a target
/// geographic coordinate without scanning every model in the collection.
///
/// The tree can be used in two ways:
///
/// 1. With any model type by providing a `coordinateProvider`.
/// 2. With a model conforming to `KDTreeCoordinateProviding`.
///
/// Example:
///
///     let tree = KDTree(models: coordinates) {
///         $0.coordinate
///     }
///
///     if let result = tree.nearest(to: tapCoordinate) {
///         print("Nearest model: \(result.model)")
///         print("Original index: \(result.index)")
///     }
public final class KDTree<Model> {

    private var root: KDTreeNode<Model>?
    private var models: [Model]
    private let coordinateProvider: (Model) -> CLLocationCoordinate2D

    /// Creates a KD-tree from the supplied models.
    ///
    /// The coordinate provider is used to extract the geographic coordinate
    /// from each model while constructing and searching the tree.
    ///
    /// - Parameters:
    ///   - models: The models to store in the KD-tree.
    ///   - coordinateProvider: A closure that returns the coordinate associated
    ///     with each model.
    ///
    /// - Complexity:
    ///   - Construction: `O(n log n)` on average.
    ///
    /// Example:
    ///
    ///     let tree = KDTree(models: coordinates) {
    ///         $0.coordinate
    ///     }
    public init(
        models: [Model],
        coordinateProvider: @escaping (Model) -> CLLocationCoordinate2D
    ) {
        self.models = models
        self.coordinateProvider = coordinateProvider
        self.root = KDTree.build(
            models: models,
            coordinateProvider: coordinateProvider,
            depth: 0
        )
    }
}

// MARK: - Coordinate Provider

/// Convenience initializers for models that provide their own coordinate.
public extension KDTree where Model: KDTreeCoordinateProviding {

    /// Creates a KD-tree using the model's `coordinate` property.
    ///
    /// This initializer is available when `Model` conforms to
    /// `KDTreeCoordinateProviding`.
    ///
    /// - Parameter models: The models to store in the KD-tree.
    ///
    /// Example:
    ///
    ///     let tree = KDTree(models: coordinates)
    convenience init(models: [Model]) {
        self.init(
            models: models,
            coordinateProvider: { $0.coordinate }
        )
    }
}

// MARK: - Search

public extension KDTree {

    /// Returns the model nearest to the specified geographic coordinate.
    ///
    /// The search uses the KD-tree to avoid scanning the entire collection.
    ///
    /// The returned index refers to the model's position in the original
    /// array supplied to the initializer, rather than the internally sorted
    /// KD-tree.
    ///
    /// - Parameter target: The geographic coordinate to search around.
    ///
    /// - Returns: A `KDTreeResult` containing the nearest model, its original
    ///   index, and its coordinate, or `nil` when the tree is empty.
    ///
    /// - Complexity:
    ///   - Average search: `O(log n)`
    ///   - Worst case: `O(n)`
    ///
    /// Example:
    ///
    ///     if let result = tree.nearest(to: tapCoordinate) {
    ///         print(result.index)
    ///     }
    func nearest(
        to target: CLLocationCoordinate2D
    ) -> KDTreeResult<Model>? {

        var bestModel: Model?
        var bestCoordinate: CLLocationCoordinate2D?
        var bestIndex = -1
        var bestDistance = Double.greatestFiniteMagnitude

        func search(_ node: KDTreeNode<Model>?) {
            guard let node else {
                return
            }

            let distance = squaredDistance(
                from: node.coordinate,
                to: target
            )

            if distance < bestDistance {
                bestDistance = distance
                bestModel = node.model
                bestCoordinate = node.coordinate
            }

            let axis = node.axis

            let targetValue = axis == 0
                ? target.latitude
                : target.longitude

            let nodeValue = axis == 0
                ? node.coordinate.latitude
                : node.coordinate.longitude

            let primary: KDTreeNode<Model>?
            let secondary: KDTreeNode<Model>?

            if targetValue < nodeValue {
                primary = node.left
                secondary = node.right
            } else {
                primary = node.right
                secondary = node.left
            }

            search(primary)

            let axisDistance = axis == 0
                ? squared(target.latitude - node.coordinate.latitude)
                : squared(target.longitude - node.coordinate.longitude)

            if axisDistance < bestDistance {
                search(secondary)
            }
        }

        search(root)

        guard let bestModel, let bestCoordinate else {
            return nil
        }

        // The KD-tree is internally sorted. Recover the original model index.
        bestIndex = models.firstIndex { model in
            areCoordinatesEqual(
                coordinateProvider(model),
                bestCoordinate
            )
        } ?? -1

        guard bestIndex >= 0 else {
            return nil
        }

        return KDTreeResult(
            model: bestModel,
            index: bestIndex,
            coordinate: bestCoordinate
        )
    }

    /// Returns the model nearest to the specified coordinate only when it is
    /// within the supplied geographic radius.
    ///
    /// This is useful for map interactions where a tap should only be
    /// considered a match when it occurs sufficiently close to a recorded
    /// route coordinate.
    ///
    /// - Parameters:
    ///   - target: The geographic coordinate to search around.
    ///   - radius: The maximum allowed distance from the target, in meters.
    ///
    /// - Returns: The nearest `KDTreeResult` when it is within `radius`;
    ///   otherwise `nil`.
    ///
    /// Example:
    ///
    ///     let result = tree.nearest(
    ///         to: tapCoordinate,
    ///         within: 50
    ///     )
    ///
    ///     if let result {
    ///         print("Found nearby coordinate: \(result.index)")
    ///     }
    func nearest(
        to target: CLLocationCoordinate2D,
        within radius: CLLocationDistance
    ) -> KDTreeResult<Model>? {

        guard let result = nearest(to: target) else {
            return nil
        }

        let targetLocation = CLLocation(
            latitude: target.latitude,
            longitude: target.longitude
        )

        let resultLocation = CLLocation(
            latitude: result.coordinate.latitude,
            longitude: result.coordinate.longitude
        )

        return targetLocation.distance(from: resultLocation) <= radius
            ? result
            : nil
    }
}

// MARK: - Update

public extension KDTree {

    /// Appends models to the existing collection and rebuilds the KD-tree.
    ///
    /// Use this when additional route coordinates need to be added to
    /// an existing tree.
    ///
    /// - Parameter newModels: Models to append to the tree.
    ///
    /// - Note: Rebuilding the tree means this operation is more expensive
    ///   than simply appending to an array.
    ///
    /// Example:
    ///
    ///     tree.update(with: newCoordinates)
    func update(with newModels: [Model]) {
        models.append(contentsOf: newModels)

        root = KDTree.build(
            models: models,
            coordinateProvider: coordinateProvider,
            depth: 0
        )
    }

    /// Replaces all existing models and rebuilds the KD-tree.
    ///
    /// - Parameter newModels: The new collection of models.
    ///
    /// Example:
    ///
    ///     tree.replace(with: updatedCoordinates)
    func replace(with newModels: [Model]) {
        models = newModels

        root = KDTree.build(
            models: models,
            coordinateProvider: coordinateProvider,
            depth: 0
        )
    }

    /// The number of models currently stored in the KD-tree.
    var count: Int {
        models.count
    }
}

// MARK: - Build

private extension KDTree {

    /// Recursively builds a balanced KD-tree by alternating between
    /// latitude and longitude as the splitting axis.
    ///
    /// - Parameters:
    ///   - models: Models belonging to the current subtree.
    ///   - coordinateProvider: Closure used to obtain coordinates.
    ///   - depth: Current tree depth, used to determine the splitting axis.
    ///
    /// - Returns: The root node of the constructed subtree.
    static func build(
        models: [Model],
        coordinateProvider: (Model) -> CLLocationCoordinate2D,
        depth: Int
    ) -> KDTreeNode<Model>? {

        guard !models.isEmpty else {
            return nil
        }

        let axis = depth % 2

        let sorted = models.sorted {
            let a = coordinateProvider($0)
            let b = coordinateProvider($1)

            return axis == 0
                ? a.latitude < b.latitude
                : a.longitude < b.longitude
        }

        let mid = sorted.count / 2
        let model = sorted[mid]
        let coordinate = coordinateProvider(model)

        let node = KDTreeNode(
            model: model,
            coordinate: coordinate,
            axis: axis
        )

        node.left = build(
            models: Array(sorted[..<mid]),
            coordinateProvider: coordinateProvider,
            depth: depth + 1
        )

        if mid + 1 < sorted.count {
            node.right = build(
                models: Array(sorted[(mid + 1)...]),
                coordinateProvider: coordinateProvider,
                depth: depth + 1
            )
        }

        return node
    }
}

// MARK: - Geometry

private extension KDTree {

    /// Calculates the squared Euclidean distance between two coordinates.
    ///
    /// Squared distance is used during KD-tree traversal because calculating
    /// a square root is unnecessary when only relative distances are needed.
    ///
    /// - Parameters:
    ///   - a: First coordinate.
    ///   - b: Second coordinate.
    ///
    /// - Returns: The squared coordinate distance.
    func squaredDistance(
        from a: CLLocationCoordinate2D,
        to b: CLLocationCoordinate2D
    ) -> Double {
        let dx = a.latitude - b.latitude
        let dy = a.longitude - b.longitude

        return dx * dx + dy * dy
    }

    /// Returns the square of a numeric value.
    ///
    /// - Parameter value: The value to square.
    /// - Returns: The squared value.
    func squared(_ value: Double) -> Double {
        value * value
    }

    /// Determines whether two coordinates have identical latitude and
    /// longitude values.
    ///
    /// - Parameters:
    ///   - lhs: First coordinate.
    ///   - rhs: Second coordinate.
    ///
    /// - Returns: `true` when both coordinates are identical.
    func areCoordinatesEqual(
        _ lhs: CLLocationCoordinate2D,
        _ rhs: CLLocationCoordinate2D
    ) -> Bool {
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
}
