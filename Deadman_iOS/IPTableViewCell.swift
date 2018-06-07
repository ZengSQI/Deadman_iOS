//
//  IPTableViewCell.swift
//  Deadman_iOS
//
//  Created by Steven Zeng on 2018/6/6.
//  Copyright © 2018年 REDEV. All rights reserved.
//

import UIKit

class IPTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var IP: UILabel!
    
    @IBOutlet weak var result: UILabel!
    
    @IBOutlet weak var indicator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
