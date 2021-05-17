//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 11/5/21.
//

import Foundation


class FlickrClient {
    static let apiKey = "2c353399228505d1c141699787e6313c"
    static let baseUrl = "https://api.flickr.com/services/rest"
    static let perPage = 30
    
    enum Endpoints {
        case searchPhotos(Int, Double, Double)
        
        var stringValue: String {
            switch self {
            case .searchPhotos(let page, let latitude, let longitude):
                return "\(baseUrl)/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(latitude)&lon=\(longitude)&per_page=\(perPage)&page=\(page)&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    
    class func getImages(page: Int, latitude: Double, longitude: Double, completion: @escaping ([String], Int, Error?) -> Void) {
        var request = URLRequest(url: Endpoints.searchPhotos(page, latitude, longitude).url)
        
        request.httpMethod = "GET"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion([], 0, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                let responseObject = try decoder.decode(SearchPhotos.self, from: data)
                var photosUrl: [String] = []
                
                for photo in responseObject.photos.photo {
                    let url = "https://live.staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                    photosUrl.append(url)
                }
                
                DispatchQueue.main.async {
                    completion(photosUrl, responseObject.photos.pages, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([], 0, error)
                }
            }
        }
        task.resume()
    }
    
    
    class func downloadImage(urlString: String, completion: @escaping (Data) -> Void) {
        let url = URL(string: urlString)
        
        if let url = url {
            let imageTask = URLSession.shared.dataTask(with: url) {
                data, response, error in
                guard let data = data else {
                    return
                }
                
                DispatchQueue.main.async {
                    completion(data)
                }
            }
            
            imageTask.resume()
        }
    }
}
