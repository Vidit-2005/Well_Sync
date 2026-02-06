//
//  DoctorActivityStatusCollectionViewController.swift
//  wellSync
//
//  Created by Vidit Agarwal on 06/02/26.
//

import UIKit

private let reuseIdentifier = "Cell"

class DoctorActivityStatusCollectionViewController: UICollectionViewController {

    var activities = ["Art","Journal","Breathing","Walking","Jogging"]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView!.register(UINib(nibName: "UploadCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "uploadCell")
        self.collectionView!.register(UINib(nibName: "GraphCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "graphCell")
        
        self.collectionView!.collectionViewLayout = generateLayout()
        // Do any additional setup after loading the view.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return activities.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if activities[indexPath.row] == "Art" || activities[indexPath.row] == "Journal" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "uploadCell", for: indexPath) as! UploadCollectionViewCell
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "graphCell", for: indexPath) as! GraphCollectionViewCell
        return cell
    }
    
    
    func generateLayout() -> UICollectionViewLayout {
        //createthe itemSize
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        
        //certe the item
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        //create teh siz eof the group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(120))
        
        //create the group
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 1)
        group.interItemSpacing = .flexible(10)
        
        //create the section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
        
    }
}
