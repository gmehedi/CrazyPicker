//
//  PcikerThumCell.swift
//  CrazyPicker
//
//  Created by Mehedi Hasan on 17/2/22.
//

import UIKit

class PickerThumCell: UICollectionViewCell {
    
    static let id = "PickerThumCell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
