import CoreLocation

/// Provides a geographic coordinate for a model stored in a `KDTree`.
///
/// Conforming a model to `KDTreeCoordinateProviding` allows a `KDTree`
/// to obtain the model's geographic location without knowing anything
/// about the application's model type.
///
/// This keeps the KD-tree implementation independent of application-specific
/// models.
///
/// A model can use `KDTree` in two ways:
///
/// 1. Conform to `KDTreeCoordinateProviding`:
///
///     struct Coordinate: KDTreeCoordinateProviding {
///         let latitude: Double
///         let longitude: Double
///
///         var coordinate: CLLocationCoordinate2D {
///             CLLocationCoordinate2D(
///                 latitude: latitude,
///                 longitude: longitude
///             )
///         }
///     }
///
///     let tree = KDTree(models: coordinates)
///
/// 2. Use a custom coordinate provider without conforming to the protocol:
///
///     struct Coordinate {
///         let latitude: Double
///         let longitude: Double
///     }
///
///     let tree = KDTree(
///         models: coordinates,
///         coordinateProvider: { model in
///             CLLocationCoordinate2D(
///                 latitude: model.latitude,
///                 longitude: model.longitude
///             )
///         }
///     )
///
/// The second approach is useful when the model belongs to another module
/// or cannot be modified to conform to this protocol.
///
/// The protocol does not require the conforming type to be a class.
/// Structs, classes, and other value/reference types can conform.
public protocol KDTreeCoordinateProviding {

    /// The geographic coordinate associated with the model.
    ///
    /// The coordinate is represented using `CLLocationCoordinate2D`,
    /// with latitude and longitude expressed in degrees.
    var coordinate: CLLocationCoordinate2D { get }
}
