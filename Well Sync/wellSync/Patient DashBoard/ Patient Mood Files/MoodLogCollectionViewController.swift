import UIKit

class MoodLogCollectionViewController:
    UICollectionViewController,
    UICollectionViewDelegateFlowLayout {
    
    var onDismiss: (() -> Void)?
    var onCheck: (()->Void)?
    var selectedMood: Int? = 2
    var selectedFeelings: [String] = []
    
    enum MoodLevel: Int {
        case verySad
        case sad
        case neutral
        case happy
        case veryHappy
    }
    
    
    let moodFeelings: [MoodLevel: [String]] = [
        .verySad: ["Angry", "Anxious", "scared", "Jealous","Overwhelmed", "Embarrassed", "Frustrated", "Anoyed", "Stressed",  "Worried", "Guilty", "Hopeless", "Iritated", "Lonely", "Discouraged","Disappointed", "Drained", "Sad"],
        .sad: ["Angry", "Anxious", "scared", "Jealous","Overwhelmed", "Embarrassed", "Frustrated", "Anoyed", "Stressed",  "Worried", "Guilty", "Hopeless", "Iritated", "Lonely", "Discouraged","Disappointed", "Drained", "Sad"],
        .neutral: ["Calm", "Balanced", "Peaceful", "Indifferent", "Content"],
        .happy: ["Amazed", "Excited", "Surprised", "Happy", "Joyful", "Brave", "Proud", "Confident", "Hopeful", "Amused", "Satisfied", "Relieved", "Grateful", "Content",  "Inspired"],
        .veryHappy: ["Amazed", "Excited", "Surprised", "Happy", "Joyful", "Brave", "Proud", "Confident", "Hopeful", "Amused", "Satisfied", "Relieved", "Grateful", "Content",  "Inspired"]
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.collectionViewLayout = generateLayout()
    }
    
    @IBAction func closeButton(_ sender: Any) {
        dismiss(animated: true) {
            self.onDismiss?()
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        3
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "MoodEntry",
                for: indexPath
            ) as! MoodEntryCollectionViewCell
            
            cell.configureTap(target: self, action: #selector(moodTapped(_:)))
            cell.configure(selectedIndex: selectedMood ?? 2)
            cell.layer.cornerRadius = 20
            
            return cell
        }
        if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FeelingCell",
                for: indexPath
            ) as! FeelingCollectionViewCell
            
            if let mood = MoodLevel(rawValue: selectedMood ?? 2),
               let feelings = moodFeelings[mood] {
                cell.configure(feelings: feelings)
            }
            
            cell.onSelectionChanged = { [weak self] selectedFeelings in
                self?.selectedFeelings = selectedFeelings
                print("Selected feelings: \(selectedFeelings)")
            }
            
            return cell
        }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "noteCell",
            for: indexPath
        )
        return cell
        
    }
    
    @objc func moodTapped(_ sender: UITapGestureRecognizer) {
        guard let selectedView = sender.view else { return }
        selectedMood = selectedView.tag
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cardWidth = collectionView.frame.width - 24
        
        switch indexPath.section {
            
        case 0:
            return CGSize(width: cardWidth, height: 180)
            
        case 1:
            let feelingCount = {
                if let mood = MoodLevel(rawValue: selectedMood ?? 2),
                   let feelings = moodFeelings[mood] {
                    return feelings.count
                }
                return 5
            }()
            let chipsPerRow: CGFloat = 4
            let chipHeight: CGFloat  = 36
            let chipSpacing: CGFloat = 5
            let rows = ceil(CGFloat(feelingCount) / chipsPerRow)
            let chipsHeight = (rows * chipHeight) + ((rows - 1) * chipSpacing)
            let titleHeight: CGFloat = 44
            let padding: CGFloat     = 32
            
            return CGSize(width: cardWidth + 4, height: chipsHeight + titleHeight + padding)
            
        default:
            return CGSize(width: cardWidth + 4, height: 220)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        
        layout.minimumInteritemSpacing = 4
        
        layout.minimumLineSpacing = 12
        
        layout.sectionInset = UIEdgeInsets(top: 16, left: 12, bottom: 8, right: 12)
        
        return layout
    }
    
    @IBAction func logMood(_ sender: UIBarButtonItem) {
        
    }
    
}
