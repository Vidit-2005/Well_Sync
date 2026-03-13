//
//  ReportAddHeadingView.swift
//  wellSync
//
//  Created by GEU on 13/03/26.
//

import UIKit

class ReportAddHeadingView: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var reportAttachment: UIButton!

    var selectedMenu: ((String) -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        addMenu()
    }
    func configure(title: String){
        self.titleLabel.text = title
       
    }
    func addMenu(){
        let camera = UIAction(title: "Camera", image: UIImage(systemName: "camera")) { _ in
            self.selectedMenu?("camera")
        }
        let photoLibrary = UIAction(title: "Photo Library", image: UIImage(systemName: "photo")) { _ in
            self.selectedMenu?("photo")
        }
        let doc = UIAction(title: "Attach Documnent", image: UIImage(systemName: "doc")) { _ in
            self.selectedMenu?("document")
        }
//        let cancel = UIAction(title: "Cancel", attributes: .destructive) { _ in
//            print("You chose Cancel")
//        }
        reportAttachment.menu = UIMenu(title: "", children: [camera, photoLibrary, doc])
        reportAttachment.showsMenuAsPrimaryAction = true
    }
}

