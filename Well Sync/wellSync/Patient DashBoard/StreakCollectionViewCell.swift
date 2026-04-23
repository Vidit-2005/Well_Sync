import UIKit

class StreakCollectionViewCell: UICollectionViewCell {
    
    // 1. Connect these as "Outlet Collections" in your XIB!
    @IBOutlet var dayCircles: [UIView]!
    @IBOutlet var dateLabels: [UILabel]!
    
    // 2. Connect these as standard Outlets
    @IBOutlet weak var streakCountLabel: UILabel!
    @IBOutlet weak var streakUnitLabel: UILabel!

    func configure(with streakData: [(date: Date, isCompleted: Bool)], currentStreak: Int) {
        // SAFETY CHECK: Prevents the "nil" crash if you forgot a connection
        guard dayCircles != nil, dateLabels != nil else {
            print("❌ ERROR: dayCircles or dateLabels outlets are NOT connected in XIB")
            return
        }

        streakCountLabel?.text = "\(currentStreak)"
        streakUnitLabel?.text = currentStreak == 1 ? "Day" : "Days"

        let calendar = Calendar.current
        for i in 0..<min(streakData.count, dayCircles.count) {
            let data = streakData[i]
            let dayNumber = calendar.component(.day, from: data.date)
            
            dateLabels[i].text = "\(dayNumber)"
            let brandBlue = UIColor(red: 0/255, green: 200/255, blue: 179/255, alpha: 0.1)
            
            if data.isCompleted {
                dayCircles[i].backgroundColor = brandBlue.withAlphaComponent(0.85)
                dateLabels[i].textColor = .white
            } else {
                dayCircles[i].backgroundColor = UIColor(white: 1.0, alpha: 0.1)
                dateLabels[i].textColor = .label
            }
            
            dayCircles[i].layer.cornerRadius = dayCircles[i].frame.height / 2
        }
    }
}
