//
//  FileListTableViewCell.swift
//  MyAdvancedRecorder
//
//  Created by Linsw on 15/12/22.
//  Copyright © 2015年 Linsw. All rights reserved.
//

import UIKit

class FileListTableViewCell: UITableViewCell {

    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var recordDateLabel: UILabel!
    @IBOutlet weak var recordImage: UIImageView!
    @IBOutlet weak var recordDurationLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
