//
//  CollectionView+Extensions.swift
//  Virtual Tourist
//
//  Created by Galina Niukhalova on 16/5/21.
//

import UIKit

extension UICollectionView {
    func setEmptyPlaceholder(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textAlignment = .center;
        
        self.backgroundView = messageLabel;
    }
    
    func setLoading(_ isLoading: Bool) {
        if !isLoading {
            self.backgroundView = nil;
            return
        }
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .lightGray
        self.backgroundView = activityIndicator;
        
        activityIndicator.startAnimating()
    }
}
