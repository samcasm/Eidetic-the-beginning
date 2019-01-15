//
//  DirectoryCell.swift
//  Eidetic
//
//  Created by user145467 on 11/23/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import UIKit

class DirectoryCell: UICollectionViewCell {
    @IBOutlet weak var directoryName: UILabel!
    
    override var isSelected: Bool{
        didSet{
            if self.isSelected
            {
                self.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
            }
            else
            {
                self.transform = CGAffineTransform.identity
            }
        }
    }
}
