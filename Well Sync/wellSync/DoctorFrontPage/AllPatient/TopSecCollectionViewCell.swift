//
//  TopSecCollectionViewCell.swift
//  wellSync
//
//  Created by Pranjal on 11/03/26.
//

import UIKit

class TopSecCollectionViewCell: UICollectionViewCell, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!

    var onSearchTextChanged: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        style(self)

        searchBar.delegate = self
        searchBar.placeholder = "Search patients..."
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        onSearchTextChanged?(searchText)
    }
}
