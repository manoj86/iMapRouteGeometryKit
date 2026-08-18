import CoreLocation

/// A generic two-dimensional KD-tree for map-route coordinates.
///
/// The tree stores any model type. The caller supplies a coordinate provider
/// so the package has no dependency on an application's model type.
public final class KDTree<Model> {
    
    private var root: KDTreeNode<Model>?
    private var models: [Model]
    private let coordinateProvider: (Model) -> CLLocationCoordinate2D
    
    // For models that don't conform
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

// For models conforming to KDTreeCoordinateProviding
public extension KDTree where Model: KDTreeCoordinateProviding {
    convenience init(models: [Model]) {
        self.init(
            models: models,
            coordinateProvider: { $0.coordinate }
        )
    }
}

public extension KDTree {
    // MARK: - Build
    private static func build(
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
    
    // MARK: - Nearest Search
    
    /// Returns the nearest model and its original model-array index.
    ///
    /// The returned index refers to the order supplied to `init(models:)`,
    /// not the internally sorted KD-tree order.
    public func nearest(
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
        
        // The KD tree is internally sorted. Recovering the original index
        // is O(n), which preserves the behavior of the supplied iKDTree
        // while removing its application-specific cooId requirement.
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
    
    /// Returns the nearest model only when the nearest coordinate is within
    /// the supplied geographic radius in meters.
    public func nearest(
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
    
    // MARK: - Update
    
    /// Appends models and rebuilds the KD-tree.
    ///
    /// This mirrors the update behavior of the supplied iKDTree.
    public func update(with newModels: [Model]) {
        models.append(contentsOf: newModels)
        
        root = KDTree.build(
            models: models,
            coordinateProvider: coordinateProvider,
            depth: 0
        )
    }
    
    /// Replaces the current models and rebuilds the KD-tree.
    public func replace(with newModels: [Model]) {
        models = newModels
        
        root = KDTree.build(
            models: models,
            coordinateProvider: coordinateProvider,
            depth: 0
        )
    }
    
    public var count: Int {
        models.count
    }
    
    // MARK: - Geometry
    
    private func squaredDistance(
        from a: CLLocationCoordinate2D,
        to b: CLLocationCoordinate2D
    ) -> Double {
        let dx = a.latitude - b.latitude
        let dy = a.longitude - b.longitude
        
        return dx * dx + dy * dy
    }
    
    private func squared(_ value: Double) -> Double {
        value * value
    }
    
    private func areCoordinatesEqual(
        _ lhs: CLLocationCoordinate2D,
        _ rhs: CLLocationCoordinate2D
    ) -> Bool {
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
}
