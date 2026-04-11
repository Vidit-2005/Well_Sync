//
//  UploadCollectionViewCell.swift
//  wellSync
//
//  Created by Vidit Agarwal on 06/02/26.
//

import UIKit

class UploadCollectionViewCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(with logs: [ActivityLog]) {
        
        let sorted = logs.sorted { $0.date > $1.date }
        
        let images = sorted.compactMap { $0.uploadPath }
        
        let first = images.indices.contains(0) ? images[0] : nil
        let second = images.indices.contains(1) ? images[1] : nil
        
        let remaining = max(0, images.count - 2)
        
        if let img1 = viewWithTag(101) as? UIImageView {
            loadImage(path: first, into: img1)
        }
        
        if let img2 = viewWithTag(102) as? UIImageView {
            loadImage(path: second, into: img2)
        }
        
        if let label = viewWithTag(103) as? UILabel {
            label.text = remaining > 0 ? "+\(remaining)" : ""
            label.isHidden = remaining == 0
        }
    }
    
    func loadImage(path: String?, into imageView: UIImageView) {
        imageView.image = nil
        
        guard let path else { return }
        
        Task {
            do {
                let image = try await AccessSupabase.shared.downloadImage(path: path)
                
                await MainActor.run {
                    imageView.image = image
                }
            } catch {
                print("Image load failed:", error)
            }
        }
    }

}
