//
//  CaseHistoryViewController.swift
//  wellSync
//
//  Created by GEU on 09/03/26.
//

import UIKit

class CaseHistoryViewController: UIViewController {
    
    @IBOutlet weak var caseHistoryColectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        caseHistoryColectionView.register(UINib(nibName: "ReportCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ReportCell")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CaseHistoryViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReportCell", for: indexPath)
        
        if let reportCell = cell as? ReportCollectionViewCell{
            reportCell.configureCell()
        }
        return cell
        
    }
}
