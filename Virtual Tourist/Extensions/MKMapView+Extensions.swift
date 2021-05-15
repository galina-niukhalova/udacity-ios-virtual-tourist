//
//  MapView+Extensions.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 15/5/21.
//

import Foundation
import MapKit

extension MKMapView {
    func disableUserInteractions() {
        self.isZoomEnabled = false
        self.isScrollEnabled = false
        self.isUserInteractionEnabled = false
    }
}
