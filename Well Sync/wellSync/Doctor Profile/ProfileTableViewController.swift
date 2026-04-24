//
//  ProfileTableViewController.swift
//  wellSync
//
//  Created by Vidit Agarwal on 14/02/26.
//

import UIKit

class ProfileTableViewController: UITableViewController {

    @IBOutlet var doctorNameLabel: UILabel!
    @IBOutlet var doctorCityLabel: UILabel!
    @IBOutlet var doctorAgeLabel: UILabel!
    @IBOutlet var doctorExperienceLabel: UILabel!
    @IBOutlet var doctorMailLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        filldata();
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
}
