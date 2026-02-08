//
//  SummmaryMoodTableViewCell.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 07/02/26.
//

import UIKit

class SummmaryMoodTableViewCell: UITableViewCell,
                                 UICollectionViewDelegate,
                                 UICollectionViewDataSource,
                                 UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "vitalCell", for: indexPath)
        return cell
    }
    

    @IBOutlet weak var collectionView: UICollectionView!

    var items: [String] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupCollection()
    }

    func setupCollection() {

            collectionView.delegate = self
            collectionView.dataSource = self

//            collectionView.register(
//                UINib(nibName: "ActivityCollectionCell", bundle: nil),
//                forCellWithReuseIdentifier: "sMood"
//            )
            collectionView.register(UINib(nibName: "VitalsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "vitalCell")
        collectionView.collectionViewLayout = generateLayout()

        }
    
    func generateLayout() -> UICollectionViewCompositionalLayout {
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(280)
        )
        
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        group.interItemSpacing = .fixed(8)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)
        
        
        return UICollectionViewCompositionalLayout(section: section)

    }
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }

}
