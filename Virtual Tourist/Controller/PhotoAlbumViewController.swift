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
    @IBOutlet var newCollectionButton: UIButton!
    
    var pin: Pin!
    
    var dataController: DataController!
    
    var photosUrl: [String] = []
    var photos: [Photo] = []
    
    // Flickr search photos response
    var availablePages: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showNavigationBar()
        
        addPinToTheMap()
        zoomIntoRegion()
        mapView.disableUserInteractions()
        
        photos = fetchPhotosFromPersistentStore()
        
        // Photos from persistent store
        if photos.count > 0 {
            collectionView.reloadData()
            setNewCollectionButtonState()
        } else {
            // No photos in the persistent store, load from flickr
            collectionView.setLoading(true)
            FlickrClient.getImages(page: 1, latitude: pin.latitude, longitude: pin.longitude, completion: handleLoadingPhotosFromFlickr)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setCollectionStyling()
    }
    
    @IBAction func handleNewCollectionButtonClick(_ sender: Any) {
        photosUrl = []
        photos = []
        
        collectionView.setLoading(true)
        newCollectionButton.isEnabled = false
        collectionView.reloadData()
        
        FlickrClient.getImages(page: getRandomPage(), latitude: pin.latitude, longitude: pin.longitude, completion: handleLoadingPhotosFromFlickr)
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
    
    func showNavigationBar() {
        navigationController?.isNavigationBarHidden = false
    }
    
    func setNewCollectionButtonState() {
        newCollectionButton.isEnabled = !isPhotosLoading()
    }
    
    func isPhotosLoading() -> Bool {
        return photosUrl.count > photos.count
    }
    
    // MARK: Map
    
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
        let numberUrls = photosUrl.count
        
        if numberUrls > 0 {
            return numberUrls
        }
        
        return photos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCellIdentifier", for: indexPath) as! PhotoAlbumCollectionViewCell
        let placeholderImage = UIImage(named: "VirtualTourist")
        
        // image is downloaded
        if photos.count > indexPath.row {
            if let imageData = photos[indexPath.row].data {
                cell.imageView.image = UIImage(data: imageData)
            } else {
                cell.imageView.image = placeholderImage
            }
        } else {
            // image is not downloaded yet
            cell.imageView.image = placeholderImage
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isPhotosLoading() else {
            // photos are still loading
            return
        }
        
        let indexToDelete = indexPath.row
        
        removePhotoFromPersistentStore(index: indexToDelete)
        
        
        if photos.count > indexToDelete {
            photos.remove(at: indexToDelete)
        }
        
        
        if photosUrl.count > indexToDelete {
            photosUrl.remove(at: indexToDelete)
        }
        
        collectionView.reloadData()
    }
    
    // MARK: Flickr
    
    func handleLoadingPhotosFromFlickr(photosUrl: [String], pages: Int, error: Error?) {
        self.photosUrl = photosUrl
        availablePages = pages
        
        setNewCollectionButtonState()
        collectionView.setLoading(false)
        collectionView.reloadData()
        
        // No images for the pin
        if photosUrl.count == 0 {
            collectionView.setEmptyPlaceholder("There is no images for the current location")
        }
        
        for url in photosUrl {
            self.downloadImage(urlString: url) { (data) in
                let photo = self.addPhotoToPersistentStore(data: data)
                self.photos.insert(photo, at: 0)
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.setNewCollectionButtonState()
                }
            }
        }
    }
    
    func downloadImage(urlString: String, completion: @escaping (Data) -> Void) {
        let url = URL(string: urlString)
        
        if let url = url {
            let imageTask = URLSession.shared.dataTask(with: url) {
                data, response, error in
                guard let data = data else {
                    return
                }
                
                completion(data)
            }
            
            imageTask.resume()
        }
    }
    
    func getRandomPage() -> Int {
        if availablePages == 0 {
            return 1
        }
        
        return Int.random(in: 1...availablePages)
    }
    
    // MARK: Persistent Store
    
    func addPhotoToPersistentStore(data: Data) -> Photo {
        let photo = Photo(context: self.dataController.viewContext)
        
        photo.pin = self.pin
        photo.data = data
        
        try? dataController.viewContext.save()
        
        return photo
    }
    
    func removePhotoFromPersistentStore(index: Int) {
        dataController.viewContext.delete(photos[index])
        
        try? dataController.viewContext.save()
    }
    
    
    func fetchPhotosFromPersistentStore() -> [Photo] {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // sort
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // filter by pin
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            return result
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
}
