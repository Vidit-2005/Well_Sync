////
////  ActivityTableViewController.swift
////  patientSide
////
////  Created by Rishika Mittal on 27/01/26.
////
//

// ActivityTableViewController.swift
import UIKit

class ActivityTableViewController: UITableViewController {

    // MARK: - Data
    var todayItems:   [TodayActivityItem] = []
    var logSummaries: [LogSummaryItem]    = []        // ← was missing, caused the error

    let currentPatientID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    let sectionTitles    = ["Today", "Logs"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle     = .none
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        loadData()
    }

    // MARK: - Data Loading
    private func loadData() {
        todayItems   = buildTodayItems(for: currentPatientID)
        logSummaries = buildLogSummaries(for: currentPatientID)  // ← was missing
        tableView.reloadData()
    }

    // MARK: - Sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:  return todayItems.count
        case 1:  return logSummaries.count    // ← was logItems.count
        default: return 0
        }
    }

    // MARK: - Cell
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "activityCell",
            for: indexPath
        ) as! TodayTableViewCell

        if indexPath.section == 0 {
            cell.configure(with: todayItems[indexPath.row])
        } else {
            let summary = logSummaries[indexPath.row]   // ← now works
            cell.configureAsLog(
                activityName: summary.activity.name,
                iconName:     summary.activity.iconName,
                logCount:     summary.totalLogs
            )
        }

        return cell
    }

    // MARK: - Section Headers
    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {

        let headerView    = UIView()

        let titleLabel    = UILabel()
        titleLabel.font   = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .label

        let subtitleLabel    = UILabel()
        subtitleLabel.font   = UIFont.preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .secondaryLabel

        if section == 0 {
            let completed      = todayItems.filter { $0.isCompletedToday }.count
            let pending        = todayItems.count - completed
            titleLabel.text    = "Today"
            subtitleLabel.text = "\(pending) pending · \(completed) completed"
        } else {
            titleLabel.text    = "Logs"
            subtitleLabel.text = "\(logSummaries.count) activities logged"
        }

        titleLabel.translatesAutoresizingMaskIntoConstraints    = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0)
        ])

        return headerView
    }

    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
}//```
//
//---
//
//## What Each Part Does
//```
//buildTodayItems(for:)
//   └── filters assignedActivities where isActiveToday == true
//   └── matches each to its Activity in activityCatalog
//   └── counts activityLogs for today
//   └── returns [TodayActivityItem]
//
//TodayActivityItem
//   └── holds everything one cell needs
//   └── computes remaining, progressRatio, isCompletedToday
//
//TodayTableViewCell.configure(with item:)
//   └── titleLabel    ← activity.name
//   └── dateLabel     ← "1 of 2 done today"
//   └── subtitleLabel ← doctorNote
//   └── iconImageView ← SF Symbol from activity.iconName
//   └── alpha 0.45    ← if fully completed
//
//ActivityTableViewController
//   └── section 0 → todayItems  (TodayActivityItem)
//   └── section 1 → logItems    (ActivityLog, sorted newest first)
//   └── header subtitle uses real computed completed/pending counts
//import UIKit
//
//class ActivityTableViewController: UITableViewController {
//    let sectionTitles = ["Today", "Logs"]
//
//    var sectionData: [[Activity]] = []
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        tableView.separatorStyle = .none
////        tableView.backgroundColor = UIColor.systemGroupedBackground
//        tableView.rowHeight = UITableView.automaticDimension
////        tableView.estimatedRowHeight = 180
//    }
//
//    // MARK: - Table view data source
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return sectionData.count
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return sectionData[section].count
//    }
//
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "today", for: indexPath) as! TodayTableViewCell
//        let activity = sectionData[indexPath.section][indexPath.row]
////        cell.selectionStyle = .none
//        cell.selectedBackgroundView = UIView()
//        cell.selectedBackgroundView?.backgroundColor = .clear
//
//        cell.configure(with: activity)
//        return cell
//    }
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//
//        let headerView = UIView()
////        headerView.backgroundColor = .systemBackground
//
//        let titleLabel = UILabel()
//        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
//        titleLabel.textColor = .systemGray
//
//        let subtitleLabel = UILabel()
//        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
//        subtitleLabel.textColor = .secondaryLabel
//
//        if section == 0 {
//            let todayActivities = sectionData[0]
//            let completed = 5
//            let pending = todayActivities.count - completed
//
//            titleLabel.text = "Today"
//            subtitleLabel.text = "\(pending) pending · \(completed) completed"
//        } else {
//            titleLabel.text = "Logs"
//            subtitleLabel.text = ""
//        }
//
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        headerView.addSubview(titleLabel)
//        headerView.addSubview(subtitleLabel)
//
//        NSLayoutConstraint.activate([
//            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
//            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: -16),
//
//            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
//            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: -8),
//            subtitleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -6)
//        ])
//
//        return headerView
//    }
//
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return section == 0 ? 40 : 20
//    }
//
//
//    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        if let header = view as? UITableViewHeaderFooterView {
//            header.textLabel?.numberOfLines = 0
//            header.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
//            header.textLabel?.textColor = .secondaryLabel
//            
//            header.textLabel?.lineBreakMode = .byWordWrapping
//        }
//    }
//
//
//    /*
//    // Override to support conditional editing of the table view.
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        return true
//    }
//    */
//
//    /*
//    // Override to support editing the table view.
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            // Delete the row from the data source
//            tableView.deleteRows(at: [indexPath], with: .fade)
//        } else if editingStyle == .insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }    
//    }
//    */
//
//    /*
//    // Override to support rearranging the table view.
//    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
//
//    }
//    */
//
//    /*
//    // Override to support conditional rearranging of the table view.
//    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the item to be re-orderable.
//        return true
//    }
//    */
//
//    /*
//    // MARK: - Navigation
//
//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destination.
//        // Pass the selected object to the new view controller.
//    }
//    */
//
//}
