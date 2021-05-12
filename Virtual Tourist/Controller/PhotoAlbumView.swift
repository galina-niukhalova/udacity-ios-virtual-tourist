//
//  PhotoAlbumView.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 10/5/21.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    var dataController: DataController!
    
    var pin: Pin!
    var fetchResultsController: NSFetchedResultsController<Photo>!
    var photosUrl: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPinToTheMap()
        zoomIntoRegion()
        
        getPersistedPhotos()
        
        if fetchResultsController?.fetchedObjects?.count == 0 {
            FlickrClient.getImages(latitude: pin.latitude, longitude: pin.longitude) { (photosUrl, error) in
                self.photosUrl = photosUrl
                self.collectionView.reloadData()
                
                // No images for the pin
                if photosUrl.count == 0 {
                    // TODO: show "No images" label
                }
                
                // TODO: update gallery
                for url in photosUrl {
                    self.persistImage(urlString: url)
                }
            }
        } else {
            print("Load from persisted storage ....")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchResultsController = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setCollectionStyling()
    }
    
    func setCollectionStyling() {
        let space: CGFloat = 3.0
        
        // set 3 items in a row for Portrait orientation and 6 items in a row of Landscape one
        let dimension = view.frame.width < view.frame.height
            ? (view.frame.width - (2 * space)) / 3.0
            : (view.frame.width - (5 * space)) / 6.0
        
        // The minimum spacing to use between items in the same row.
        flowLayout.minimumInteritemSpacing = space
        // The minimum spacing to use between lines of items in the grid.
        flowLayout.minimumLineSpacing = space
        
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func addPinToTheMap() {
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func zoomIntoRegion() {
        let latDelta:CLLocationDegrees = 0.01
        let lonDelta:CLLocationDegrees = 0.01
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: false)
    }
    
    // MARK: Collection data
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfPersistedPhotos = fetchResultsController?.sections?[section].numberOfObjects
        let numberUrls = photosUrl.count
        
        if numberUrls > 0 {
            return numberUrls
        }
        
        return numberOfPersistedPhotos ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCellIdentifier", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        let persistedImages = fetchResultsController.fetchedObjects ?? []
        print("count: \(fetchResultsController?.sections?[0].numberOfObjects ?? 0)")
        if persistedImages.count > indexPath.row {
            if let imageData = persistedImages[indexPath.row].data {
                cell.imageView.image = UIImage(data: imageData)
            } else {
                cell.imageView.image = UIImage(named: "VirtualTourist")
            }
        } else {
            cell.imageView.image = UIImage(named: "VirtualTourist")
        }
        
        return cell
    }
    
    func persistImage(urlString: String) {
        let url = URL(string: urlString)
        
        if let url = url {
            let imageTask = URLSession.shared.dataTask(with: url) {
                data, response, error in
                guard let data = data else {
                    return
                }
                
                let photo = Photo(context: self.dataController.viewContext)
                
                photo.pin = self.pin
                photo.data = data
                photo.creationDate = Date()
                    
                try? self.dataController.viewContext.save()

            }
            
            imageTask.resume()
        }
    }
    
    func getPersistedPhotos() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // sort
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // filter by pin
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
}
