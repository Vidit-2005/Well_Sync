//
//  AddActivityTableViewController.swift
//  wellSync
//
//  Created by Vidit Saran Agarwal on 07/02/26.
//

import UIKit

class AddActivityTableViewController: UITableViewController {

    @IBOutlet weak var activityListButton: UIButton!
    @IBOutlet weak var frequencyButton: UIButton!
    @IBOutlet weak var activityTimingButton: UIButton!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var doctorNote: UITextView!
    @IBOutlet weak var activityCell: UITableViewCell!
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var typeCell: UITableViewCell!
    
    var isCustomSelected = false

    override func viewDidLoad() {
        super.viewDidLoad()

        doctorNote.layer.cornerRadius = 20
        doctorNote.clipsToBounds = true
        setupActivityMenu()
    }
    func setupActivityMenu() {

            let activityList = ["Journaling", "Art", "Exercise", "Breathing", "Custom"]
            let frequencyList = ["Once a day","Twice a day","Once a week", "Twice a week","Alternate days"]
            let timingList = ["Morning","Afternoon", "Evening"]
            let typeList = ["Upload","Graph"]


            // 🔥 Activity menu (important part)
            let activityActions = activityList.map { option in
                UIAction(title: option) { [weak self] _ in
                    guard let self = self else { return }

                    self.activityListButton.setTitle(option, for: .normal)

                    // ⭐ show/hide extra rows
                    self.toggleCustomRows(show: option == "Custom")
                }
            }

            activityListButton.menu = UIMenu(children: activityActions)
            activityListButton.showsMenuAsPrimaryAction = true


            // Frequency
            let frequencyActions = frequencyList.map { option in
                UIAction(title: option) { [weak self] _ in
                    self?.frequencyButton.setTitle(option, for: .normal)
                }
            }


            frequencyButton.menu = UIMenu(children: frequencyActions)
            frequencyButton.showsMenuAsPrimaryAction = true


            // Timing
            let timingActions = timingList.map { option in
                UIAction(title: option) { [weak self] _ in
                    self?.activityTimingButton.setTitle(option, for: .normal)
                }
            }


            activityTimingButton.menu = UIMenu(children: timingActions)
            activityTimingButton.showsMenuAsPrimaryAction = true
        
            // Type
            let typeActions = typeList.map { option in
                UIAction(title: option) { [weak self] _ in
                    self?.typeButton.setTitle(option, for: .normal)
                }
            }


        typeButton.menu = UIMenu(children: typeActions)
        typeButton.showsMenuAsPrimaryAction = true
        
        
        }


        // MARK: - Dynamic Row Logic

        func toggleCustomRows(show: Bool) {

            guard show != isCustomSelected else { return }

            isCustomSelected = show

            let indexPaths = [
                IndexPath(row: 1, section: 0),
                IndexPath(row: 2, section: 0)
            ]

            tableView.beginUpdates()

            if show {
                tableView.insertRows(at: indexPaths, with: .fade)
            } else {
                tableView.deleteRows(at: indexPaths, with: .fade)
            }

            tableView.endUpdates()
        }


        // MARK: - TableView DataSource

        override func tableView(_ tableView: UITableView,
                                numberOfRowsInSection section: Int) -> Int {

            // Section 0 = Activity section
            if section == 0 {
                return isCustomSelected ? 3 : 1
            }

            return super.tableView(tableView, numberOfRowsInSection: section)
        }


        override func tableView(_ tableView: UITableView,
                                cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            // Section 0 dynamic rows
            if indexPath.section == 0 {

                switch indexPath.row {
                case 0:
                    return activityCell
                case 1:
                    return nameCell
                case 2:
                    return typeCell
                default:
                    break
                }
            }

            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
