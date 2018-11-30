//
//  PhotoCell.swift
//  Eidetic
//
//  Created by user145467 on 11/16/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoBadgeImageView: UIImageView!
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    var livePhotoBadgeImage: UIImage! {
        didSet {
            livePhotoBadgeImageView.image = livePhotoBadgeImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        livePhotoBadgeImageView.image = nil
    }
    
    override var isSelected: Bool{
        didSet{
            let checkmarkOnCell = self.viewWithTag(12) as? UIImageView
            if self.isSelected
            {
                checkmarkOnCell?.isHidden = false
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                
            }
            else
            {
                checkmarkOnCell?.isHidden = true
                self.transform = CGAffineTransform.identity
                
            }
        }
    }

}
