//
//  DetailSessionCollectionViewController.swift
//  wellSync
//
//  Created by Vidit Agarwal on 11/03/26.
//

import UIKit
import AVFoundation

class DetailSessionCollectionViewController: UICollectionViewController {
    
    var session: SessionNote?

    var images: [UIImage] = []
    var audioURLs: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = generateLayout()

        Task {
            await loadMedia()
        }
    }

//    func loadMedia() async {
//        guard let session = session else { return }
//
//        await withTaskGroup(of: Void.self) { group in
//
//            // Images
//            if let imagePaths = session.images {
//                for path in imagePaths {
//                    group.addTask {
//                        do {
//                            let img = try await SupabaseManager.shared.downloadSessionImage(from: path)
//                            await MainActor.run {
//                                self.images.append(img)
//                                self.collectionView.reloadSections(IndexSet(integer: 1))
//                            }
//                        } catch {
//                            print("❌ Image load error:", error)
//                        }
//                    }
//                }
//            }
//
//            // Audio
//            if let audioPaths = session.voice {
//                for path in audioPaths {
//                    group.addTask {
//                        do {
//                            let url = try await SupabaseManager.shared.downloadAudioToLocal(from: path)
//                            await MainActor.run {
//                                self.audioURLs.append(url)
//                                self.collectionView.reloadSections(IndexSet(integer: 0))
//                            }
//                        } catch {
//                            print("❌ Audio load error:", error)
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    func loadMedia() async {
        guard let session = session else { return }

        do {
            // Images
            if let imagePaths = session.images {
                for path in imagePaths {
                    let img = try await SupabaseManager.shared.downloadSessionImage(from: path)
                    images.append(img)
                }
            }

            // Audio
            if let audioPaths = session.voice {
                for path in audioPaths {
                    let localURL = try await SupabaseManager.shared.downloadAudioToLocal(from: path)
                    audioURLs.append(localURL)
                }
            }

            await MainActor.run {
                self.collectionView.reloadData()
            }

        } catch {
            print("❌ Media load error:", error)
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView,
                                numberOfItemsInSection section: Int) -> Int {

        switch section {
        case 1:
            return audioURLs.isEmpty ? 0 : audioURLs.count
        case 2:
            return images.isEmpty ? 0 : images.count
        case 0:
            return session?.notes == nil ? 0 : 1
        default:
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "recording",
                for: indexPath
            ) as! deatilCollectionViewCell

            let url = audioURLs[indexPath.item]
            cell.configure(with: url)

            return cell
        }
        if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "images",
                for: indexPath
            ) as! ImageCollectionViewCell

            cell.configure(with: images[indexPath.item])
            return cell
        }
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "textNote",
                for: indexPath
            ) as! textCollectionViewCell

            cell.textNote.text = session?.notes
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recording", for: indexPath)
    
        return cell
    }
    func generateLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout {
 sectionIndex,
 environment in
            if sectionIndex == 1 {

                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(150)
                )
                
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9),
                    heightDimension: .absolute(150)
                )

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 16, trailing: 10)
                section.interGroupSpacing = 4
                section.orthogonalScrollingBehavior = .groupPagingCentered

                return section
            }
            if sectionIndex == 2 {
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(150)
                )
                
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9),
                    heightDimension: .absolute(150)
                )
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitem: item,
                    count: 2
                )

                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 16, trailing: 10)
                section.interGroupSpacing = 4
                section.orthogonalScrollingBehavior = .groupPagingCentered

                return section
            }
            if sectionIndex == 0{
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension:
                        .estimated(0))
         
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
           
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension:
                        .estimated(0))
    
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
//                group.interItemSpacing = .flexible(10)
                
            
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 16, trailing: 10)
                section.interGroupSpacing = 4
                
                return section
            }
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .absolute(150))
            
       
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
         
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(150))
        
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .flexible(10)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 16, trailing: 10)
            section.interGroupSpacing = 4
            
            return section
        }
    }
}

