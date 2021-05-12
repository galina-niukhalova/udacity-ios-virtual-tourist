//
//  PhotoAlbumView.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 10/5/21.
//

import UIKit

class PhotoAlbumView: UIViewController {
    var latitude: Double!
    var longitude: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FlickrClient.getImages(latitude: latitude, longitude: longitude) { (photosUrl, error) in
            print("photosUrl: \(photosUrl)")
            
            if let error = error {
                print("error: \(error)")
            }
        }
    }
}
