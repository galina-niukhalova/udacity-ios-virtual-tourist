//
//  Photo+Extensions.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 15/5/21.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        creationDate = Date()
    }
}
