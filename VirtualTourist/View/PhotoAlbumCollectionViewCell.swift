//
//  PhotoAlbumCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Jennifer Liu on 12/11/2017.
//  Copyright © 2017 Jennifer Liu. All rights reserved.
//

import UIKit

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Properties
    
    // Toggle the alpha of selected cell
    override var isSelected: Bool {
        didSet {
            imageView.alpha = isSelected ? 0.5 : 1.0
        }
    }
}
