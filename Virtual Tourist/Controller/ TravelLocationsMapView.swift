//
//  TravelLocationsMapView.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 7/5/21.
//

import UIKit
import MapKit

class TravelLocationsMapView: UIViewController, MKMapViewDelegate {
    @IBOutlet var mapView: MKMapView!
    
    let defaults = UserDefaults.standard
    let defaultsMapRegionKey = "MapRegion"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setRegionFromDefaults()
        
        addGestureRecognizer(gestureRecognizerType: UILongPressGestureRecognizer.self)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        persistRegion()
    }
    
    // MARK: Persist the center of the map and the zoom level
    
    func persistRegion() {
        let center = mapView.region.center
        let span = mapView.region.span
        
        let lat = Double(center.latitude)
        let lng = Double(center.longitude)
        let latDelta = Double(span.latitudeDelta)
        let lngDelta = Double(span.longitudeDelta)
        
        let regionDict = ["latitude": lat, "longitude": lng, "latitudeDelta": latDelta, "longitudeDelta": lngDelta]
        
        defaults.set(regionDict, forKey: defaultsMapRegionKey)
    }

    func setRegionFromDefaults() {
        let regionDict = defaults.object(forKey: defaultsMapRegionKey) as? [String: Double] ?? [String: Double]()
        
        if let lat = regionDict["latitude"],
           let lng = regionDict["longitude"],
           let latDelta = regionDict["latitudeDelta"],
           let lngDelta = regionDict["longitudeDelta"] {
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
            let location = CLLocationCoordinate2DMake(lat, lng)
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: false)
        }
    }

    
    // MARK: Drop a new pin on tap and hold the map
    
    func addGestureRecognizer<GestureRecognizerType: UIGestureRecognizer>(gestureRecognizerType: GestureRecognizerType.Type) {
        let gestureRecognizer = GestureRecognizerType(target: self, action: #selector(handleGestureAction))
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func handleGestureAction(gestureRecognizer: UIGestureRecognizer) {
        // tap and hold event
        if let gestureLongPressRecognizer = gestureRecognizer as? UILongPressGestureRecognizer {
            let location = gestureLongPressRecognizer.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            addPin(coordinate)
        }
    }
    
    func addPin(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    // MARK: Navigate to Photo Album when a pin is tapped
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
    }
}
