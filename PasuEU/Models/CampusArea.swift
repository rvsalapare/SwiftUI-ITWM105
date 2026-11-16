import MapKit

enum CampusArea {
    static let center = CLLocationCoordinate2D(latitude: 13.948658, longitude: 121.620881)

    static let span = MKCoordinateSpan(latitudeDelta: 0.011, longitudeDelta: 0.014)

    static var region: MKCoordinateRegion {
        MKCoordinateRegion(center: center, span: span)
    }

    static let boundary: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 13.949512, longitude: 121.617867),
        CLLocationCoordinate2D(latitude: 13.949109, longitude: 121.617089),
        CLLocationCoordinate2D(latitude: 13.948649, longitude: 121.616528),
        CLLocationCoordinate2D(latitude: 13.948237, longitude: 121.616384),
        CLLocationCoordinate2D(latitude: 13.947925, longitude: 121.616231),
        CLLocationCoordinate2D(latitude: 13.947001, longitude: 121.616294),
        CLLocationCoordinate2D(latitude: 13.946287, longitude: 121.616633),
        CLLocationCoordinate2D(latitude: 13.945511, longitude: 121.617906),
        CLLocationCoordinate2D(latitude: 13.945276, longitude: 121.620352),
        CLLocationCoordinate2D(latitude: 13.946296, longitude: 121.621715),
        CLLocationCoordinate2D(latitude: 13.945859, longitude: 121.6222),
        CLLocationCoordinate2D(latitude: 13.945724, longitude: 121.622928),
        CLLocationCoordinate2D(latitude: 13.946187, longitude: 121.623498),
        CLLocationCoordinate2D(latitude: 13.946778, longitude: 121.623864),
        CLLocationCoordinate2D(latitude: 13.947428, longitude: 121.624453),
        CLLocationCoordinate2D(latitude: 13.948146, longitude: 121.624996),
        CLLocationCoordinate2D(latitude: 13.948587, longitude: 121.625347),
        CLLocationCoordinate2D(latitude: 13.949007, longitude: 121.625531),
        CLLocationCoordinate2D(latitude: 13.950105, longitude: 121.625462),
        CLLocationCoordinate2D(latitude: 13.950845, longitude: 121.625196),
        CLLocationCoordinate2D(latitude: 13.951587, longitude: 121.624585),
        CLLocationCoordinate2D(latitude: 13.95204, longitude: 121.623302),
        CLLocationCoordinate2D(latitude: 13.952033, longitude: 121.622339),
        CLLocationCoordinate2D(latitude: 13.951429, longitude: 121.620897),
        CLLocationCoordinate2D(latitude: 13.950542, longitude: 121.619799),
        CLLocationCoordinate2D(latitude: 13.950325, longitude: 121.6195),
        CLLocationCoordinate2D(latitude: 13.950065, longitude: 121.619006)
    ]
}
