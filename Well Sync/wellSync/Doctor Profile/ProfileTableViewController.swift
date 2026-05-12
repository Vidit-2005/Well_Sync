//
//  ProfileTableViewController.swift
//  wellSync
//
//  Created by Vidit Agarwal on 14/02/26.
//

import UIKit

class ProfileTableViewController: BaseInsetGroupedTableViewController {

    @IBOutlet var doctorNameLabel: UILabel!
    @IBOutlet var doctorCityLabel: UILabel!
    @IBOutlet var doctorAgeLabel: UILabel!
    @IBOutlet var doctorExperienceLabel: UILabel!
    @IBOutlet var doctorMailLabel: UILabel!
    
    private var profileCellBlue: UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.28, blue: 0.34, alpha: 1.0)
            : UIColor(red: 0.82, green: 0.90, blue: 0.92, alpha: 1.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filldata()
        tableView.reloadData()
    }
    func filldata(){
        if SessionManager.shared.currentDoctor == nil{
            return
        }
        var doctor = SessionManager.shared.currentDoctor
        doctorNameLabel.text = doctor!.name
        doctorCityLabel.text = doctor!.address
        
        doctorAgeLabel.text = String(Calendar.current.dateComponents([.year], from: doctor!.dob, to: Date()).year!)
        doctorExperienceLabel.text = String(doctor!.experience)
        doctorMailLabel.text = doctor!.email
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.section == 2 else { return }

        let storyboard = UIStoryboard(name: "DoctorDetailScreens", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(
            withIdentifier: "doctorCredentialDetail"
        ) as? DoctorCredentialDetailViewController else {
            return
        }

        switch indexPath.row {
        case 0:
            detailVC.screenType = .education
        case 1:
            detailVC.screenType = .registration
        case 2:
            detailVC.screenType = .identity
        default:
            return
        }

        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        cell.contentView.backgroundColor = profileCellBlue
    }
}
