//
//  util functions.swift
//  wellSync
//
//  Created by Rishika Mittal on 24/04/26.
//

import Foundation
import UIKit

func style(_ cell: UICollectionViewCell) {
    cell.layer.shadowColor             = UIColor.black.withAlphaComponent(0.5).cgColor
    cell.layer.shadowOpacity           = 0.25
    cell.layer.shadowOffset            = CGSize(width: 0, height: 1.0)
    cell.layer.shadowRadius            = 2
    cell.layer.masksToBounds           = false
    cell.contentView.layer.cornerRadius  = 20
    cell.contentView.layer.masksToBounds = true
    cell.layer.cornerRadius            = 20
}

func styleTableCell(_ cell: UITableViewCell) {
    cell.layer.shadowColor             = UIColor.black.withAlphaComponent(0.5).cgColor
    cell.layer.shadowOpacity           = 0.25
    cell.layer.shadowOffset            = CGSize(width: 0, height: 0)
    cell.layer.shadowRadius            = 2
    cell.layer.masksToBounds           = false
    cell.contentView.layer.cornerRadius  = 20
    cell.contentView.layer.masksToBounds = true
    cell.layer.cornerRadius            = 20
}
