//
//  ImageCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Agarwal on 30/03/26.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    func configure(with image: UIImage) {
        imageView.image = image
    }
}
