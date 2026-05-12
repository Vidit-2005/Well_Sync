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
//
//  BaseInsetGroupedTableViewController.swift
//  wellSync
//

import UIKit

class BaseInsetGroupedTableViewController: UITableViewController {
    
    var sectionShadowViews: [Int: UIView] = [:]
    
    /// Override this in subclasses to return section indices that should NOT have a shadow/card background
    var unshadowedSections: Set<Int> {
        return []
    }
    
    /// Override this to change the spacing below each section
    var sectionFooterSpacing: CGFloat {
        return 24.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure TableView for better shadows
        tableView.backgroundColor = .systemGroupedBackground
        tableView.clipsToBounds = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for section in 0..<tableView.numberOfSections {
            // Check if this section should be ignored
            if unshadowedSections.contains(section) { continue }
            
            let numberOfRows = tableView.numberOfRows(inSection: section)
            if numberOfRows == 0 { continue }
            
            let firstRowRect = tableView.rectForRow(at: IndexPath(row: 0, section: section))
            let lastRowRect = tableView.rectForRow(at: IndexPath(row: numberOfRows - 1, section: section))
            let rowsRect = firstRowRect.union(lastRowRect)
            
            // If the section isn't visible or has no rect, skip
            if rowsRect.isEmpty || rowsRect.height == 0 { continue }
            
            if sectionShadowViews[section] == nil {
                let shadowView = UIView()
                shadowView.backgroundColor = .secondarySystemGroupedBackground
                shadowView.layer.cornerRadius = 16
                shadowView.layer.shadowColor = UIColor.black.cgColor
                shadowView.layer.shadowOpacity = 0.12
                shadowView.layer.shadowOffset = CGSize(width: 0, height: 2)
                shadowView.layer.shadowRadius = 8
                shadowView.isUserInteractionEnabled = false
                
                // Insert behind all cells
                tableView.insertSubview(shadowView, at: 0)
                sectionShadowViews[section] = shadowView
            }
            
            // InsetGrouped standard margin is 20
            let horizontalMargin: CGFloat = 20
            let adjustedRect = CGRect(x: horizontalMargin, 
                                      y: rowsRect.origin.y, 
                                      width: tableView.bounds.width - (horizontalMargin * 2), 
                                      height: rowsRect.height)
            sectionShadowViews[section]?.frame = adjustedRect
        }
    }
    
    // MARK: - Section Spacing
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return sectionFooterSpacing
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    // MARK: - Cell Rendering
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .secondarySystemGroupedBackground
        
        // Remove any individual cell shadows
        cell.layer.shadowOpacity = 0
        cell.contentView.layer.masksToBounds = true
        
        // Handle unshadowed sections (like profile headers)
        if unshadowedSections.contains(indexPath.section) {
            cell.contentView.layer.cornerRadius = 20
            return
        }
        
        let rows = tableView.numberOfRows(inSection: indexPath.section)
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == rows - 1
        
        // Apply corner radius to match the shadow view behind it
        cell.contentView.layer.cornerRadius = 16
        if isFirst && isLast {
            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirst {
            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cell.contentView.layer.cornerRadius = 0
        }
    }
}
