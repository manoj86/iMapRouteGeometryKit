# iMapRouteGeometryKit

`iMapRouteGeometryKit` is a reusable Swift package for geometry and spatial
operations used by map-based route applications.

The package was created from the route interaction problems encountered in
an application that supports both Apple Maps and Google Maps.

🔥 The complete flow

<img width="1536" height="721" alt="KD-Tree" src="https://github.com/user-attachments/assets/f362821f-0c0f-44b1-82ac-32e6b9843952" />

<img width="464" height="326" alt="Query" src="https://github.com/user-attachments/assets/6b87df19-ba9d-49e6-b0bc-2baecc4f073d" />

<img width="1282" height="724" alt="Segment Cases" src="https://github.com/user-attachments/assets/72797a22-efde-4b5b-99f9-d0462e8a2425" />


                   USER TAPS MAP
                         │
                         ▼
                 Tap coordinate
                         │
                         ▼
                      KDTree
                         │
                         │ nearest recorded point
                         ▼
                KDTreeResult<Model>
                  ├── model
                  ├── index
                  └── coordinate
                         │
                         ▼
               Nearby route points
                         │
                         ▼
             PolylineProximityAnalyzer
                         │
                         │ point-to-segment distance
                         ▼
                   distance
                    /     \
                   /       \
              within       outside
             tolerance     tolerance
                 │              │
                 ▼              ▼
            ROUTE HIT       NOT A HIT



## Why this package exists

The original problem was not simply "find the nearest coordinate."

A recorded route can contain thousands of coordinates. A user can tap the
rendered blue route at a position that is far away from every recorded
coordinate because the recorded points are sparse.

A nearest-coordinate lookup can therefore produce this situation:

    Recorded points:

    P499 ----------------------------- P500
                     ^
                     |
                    tap

The tap is on the rendered route, but it may be too far from both P499 and
P500 for a simple point-distance test.

The solution developed here separates two problems:

1. KD-tree: find a nearby recorded route point efficiently.
2. Polyline proximity analysis: determine whether the tap is close to the
   line segment connecting nearby recorded points.

This package keeps those algorithms separate and map-framework independent.

## Problem history and design decisions

### 1. Large number of recorded coordinates

The route can contain thousands of recorded coordinates.

Attaching a separate tap gesture to every coordinate or overlay was rejected
because that does not scale.

The design instead uses one map-level tap gesture and performs a spatial
lookup.

### 2. Existing KD-tree

The application already had an `iKDTree` implementation.

Its original responsibilities included:

- storing application `Coordinate` models
- building a two-dimensional KD-tree
- nearest-model lookup
- nearest lookup with a radius
- projected-route lookup around the nearest model
- rebuilding the tree when new models are appended

The original implementation depended on application-specific concepts such
as `Coordinate`, `cooId`, `toDouble`, and `logger`.

This package keeps the KD-tree design as the base but makes it generic.

Instead of requiring an application-specific `Coordinate` type, callers
provide:

    KDTree(
        models: models,
        coordinateProvider: { model in
            CLLocationCoordinate2D(
                latitude: ...,
                longitude: ...
            )
        }
    )

The package therefore does not need to know what the application's model
looks like.

### 3. Preserve the route index

The original projected lookup found the nearest model and then searched the
application's model array for its `cooId` to recover the route index.

That approach is application-specific and requires an ID property.

The generic KD-tree instead returns:

    KDTreeResult<Model>

containing:

- `model`
- `index`
- `coordinate`

The index is the original index from the array supplied to the KD-tree.

This is important for route interaction because the next step needs to
inspect neighboring route points:

    index - 2
    index - 1
    index
    index + 1
    index + 2

### 4. Nearest point is not the same as nearest route

A KD-tree answers:

    "Which recorded coordinate is closest to the tap?"

That is not enough to answer:

    "Did the user tap on the blue route?"

A route is made from segments:

    P499 -> P500
    P500 -> P501

A tap can be close to the middle of a segment while being relatively far
from both endpoints.

Therefore the route hit test was separated into
`PolylineProximityAnalyzer`.

### 5. Check neighboring segments instead of thousands of points

Once the KD-tree identifies a nearby recorded point, there is no reason to
scan the entire route.

The analyzer examines a small neighborhood around the KD-tree index.

With a search radius of 2:

    P[index - 2] -> P[index - 1]
    P[index - 1] -> P[index]
    P[index]     -> P[index + 1]
    P[index + 1] -> P[index + 2]

The closest point on each candidate segment is calculated.

The segment with the smallest distance to the tap is selected.

### 6. Use screen-space tolerance

The tap is a UI interaction, so the route hit tolerance should be expressed
in screen points/pixels rather than a fixed geographic distance.

This matters because the same geographic distance has a different visual
size at different map zoom levels.

The package therefore accepts `CGPoint` values for the polyline proximity
analyzer.

Apple Maps and Google Maps can each convert their route coordinates into
screen-space points and then use the same analyzer.

### 7. Support Apple Maps and Google Maps without coupling the package

The package deliberately does not import:

- MapKit
- GoogleMaps
- SwiftUI
- Core Data
- application-specific models

Map-specific code stays in the application layer.

Conceptually:

    Apple Maps                 Google Maps
        |                          |
        | convert route            | convert route
        | coordinates              | coordinates
        v                          v
                   CGPoint
                      |
                      v
            iMapRouteGeometryKit

This allows the same route geometry algorithm to work with both map
implementations.

## Package structure

    iMapRouteGeometryKit/
    ├── Package.swift
    ├── Sources/
    │   └── iMapRouteGeometryKit/
    │       ├── KDTree/
    │       │   ├── KDTree.swift
    │       │   ├── KDTreeNode.swift
    │       │   └── KDTreeResult.swift
    │       │
    │       └── Polyline/
    │           ├── PolylineProximityAnalyzer.swift
    │           └── PolylineProximityResult.swift
    │
    └── Tests/
        └── iMapRouteGeometryKitTests/
            ├── KDTreeTests.swift
            └── PolylineProximityAnalyzerTests.swift

## KDTree usage

    import iMapRouteGeometryKit

    struct RoutePoint {
        let id: String
        let latitude: Double
        let longitude: Double
    }

    let tree = KDTree(
        models: routePoints
    ) { point in
        CLLocationCoordinate2D(
            latitude: point.latitude,
            longitude: point.longitude
        )
    }

    guard let nearest = tree.nearest(
        to: tapCoordinate
    ) else {
        return
    }

    print(nearest.model)
    print(nearest.index)

The `index` is the index in the original `routePoints` array.

## Route hit testing

After converting the relevant route coordinates into screen-space points:

    let analyzer = PolylineProximityAnalyzer(
        points: screenPoints
    )

    if let hit = analyzer.hit(
        at: tapPoint,
        around: nearest.index,
        tolerance: 15,
        searchRadius: 2
    ) {
        // The tap is on/near the route.
        //
        // hit.segmentIndex identifies:
        // segmentIndex -> segmentIndex + 1
    }

The analyzer does not need to know whether those screen points came from
Apple Maps, Google Maps, or another rendering system.

## Recommended application flow

    One map-level tap
           |
           v
    tap coordinate
           |
           v
        KDTree
           |
           v
    nearest model + index
           |
           v
    neighboring route segments
           |
           v
    PolylineProximityAnalyzer
           |
           v
    point-to-segment distance
           |
           +---- within tolerance ----> route hit
           |
           +---- outside tolerance ---> not a route hit

The overlay-selection logic remains outside this package.

## Why overlay selection is not part of this package

The geometry layer should not decide which application-specific overlay,
annotation, trip record, or Core Data object to display.

Its job is only to answer geometric questions:

- Which recorded point is nearby?
- Which route segment is nearby?
- How far is the tap from that segment?
- What is the closest point on that segment?

The application can then use the returned index/segment to select its own
overlay or route data.

## Important implementation note

The current KD-tree rebuild strategy follows the supplied application's
existing approach: adding models rebuilds the tree.

This is intentional for the first reusable version so the behavior stays
easy to understand and close to the original implementation.

For very large, frequently mutating datasets, rebuilding can become a
future optimization area.

## Future extension areas

Potential future additions include:

- k-nearest-neighbor search
- bounding-box/range search
- route snapping
- polyline simplification
- geographic segment distance
- spatial indexing improvements
- incremental KD-tree rebuild strategies
- map-framework adapters kept outside the core package

These should be added only when the application has a concrete need.

## Design principle

The package follows one central separation:

    KDTree
    "Find the nearby recorded point."

    PolylineProximityAnalyzer
    "Determine whether the tap is near the route segment."

    Application
    "Decide what overlay/data to show."

Keeping those responsibilities separate makes the code easier to test,
reuse, and eventually open-source.
