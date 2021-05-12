//
//  Search SearchPhotos.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 12/5/21.
//

import Foundation

struct SearchPhotos: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [PhotoModel]
}

struct PhotoModel: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
