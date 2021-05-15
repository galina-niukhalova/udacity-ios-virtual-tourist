//
//  TravelLocationsMapView.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 7/5/21.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapView: UIViewController, MKMapViewDelegate {
    @IBOutlet var mapView: MKMapView!
    
    var dataController: DataController!
    
    let defaults = UserDefaults.standard
    let defaultsMapRegionKey = "MapRegion"
    
    let photoAlbumStoryboardId = "PhotoAlbumIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideNavigationBar()
        
        setRegionFromUserDefaults()
        displayExistingPins()
        
        addGestureRecognizer(gestureRecognizerType: UILongPressGestureRecognizer.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideNavigationBar()
    }
    
    func hideNavigationBar() {
        navigationController?.isNavigationBarHidden = true
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        addCurrentRegionToUserDefaults()
    }
    
    
    func displayExistingPins() {
        let pins = fetchPinsFromPersistentStore()
        
        for pin in pins {
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            addPinToTheMap(coordinate)
        }
    }
    
    func addPinToTheMap(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
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
            
            addPinToTheMap(coordinate)
            addPinToPersistentStore(coordinate)
        }
    }
    
    // MARK: Navigate to Photo Album when a pin is tapped
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photoAlbumViewController = self.storyboard!.instantiateViewController(withIdentifier: photoAlbumStoryboardId) as! PhotoAlbumViewController
        let pinCoordinate = view.annotation?.coordinate
        
        if let pinCoordinate = pinCoordinate {
            // filter by geo location
            let predicate = NSPredicate(format: "latitude == %@ && longitude == %@", argumentArray: [pinCoordinate.latitude, pinCoordinate.longitude])
            
            let pins = fetchPinsFromPersistentStore(predicate: predicate)
            
            if pins.count > 0 {
                photoAlbumViewController.pin = pins[0]
            }
            
            photoAlbumViewController.dataController = dataController
            
            navigationController?.pushViewController(photoAlbumViewController, animated: true)
            
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
    }
    
    // MARK: UserDefaults
    
    func addCurrentRegionToUserDefaults() {
        let center = mapView.region.center
        let span = mapView.region.span
        
        let lat = Double(center.latitude)
        let lng = Double(center.longitude)
        let latDelta = Double(span.latitudeDelta)
        let lngDelta = Double(span.longitudeDelta)
        
        let regionDict = ["latitude": lat, "longitude": lng, "latitudeDelta": latDelta, "longitudeDelta": lngDelta]
        
        defaults.set(regionDict, forKey: defaultsMapRegionKey)
    }
    
    func setRegionFromUserDefaults() {
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
    
    
    // MARK: Persistent Store
    
    func fetchPinsFromPersistentStore(predicate: NSPredicate? = nil) -> [Pin] {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        // sort
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // filter
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            return result
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func addPinToPersistentStore(_ coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        
        try? dataController.viewContext.save()
    }
}
