import UIKit

final class WellSyncOnboardingViewController: UIViewController {

    @IBOutlet private weak var topAccentView: UIView!
    @IBOutlet private weak var bottomAccentView: UIView!
    @IBOutlet private weak var skipButton: UIButton!
    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var iconContainerView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bulletOneLabel: UILabel!
    @IBOutlet private weak var bulletTwoLabel: UILabel!
    @IBOutlet private weak var bulletThreeLabel: UILabel!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var nextButton: UIButton!

    var onFinish: (() -> Void)?

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            tag: "TRACK",
            title: "Track daily wellbeing",
            bullets: [
                "Mood check-ins",
                "Activity updates",
                "Quick journal notes"
            ],
            symbolName: "heart.text.square.fill",
            accentColor: Palette.primaryCyan
        ),
        OnboardingSlide(
            tag: "REVIEW",
            title: "Review progress in one place",
            bullets: [
                "Daily trends",
                "Session notes",
                "Case history summaries"
            ],
            symbolName: "chart.line.uptrend.xyaxis",
            accentColor: Palette.actionBlue
        ),
        OnboardingSlide(
            tag: "SHARE",
            title: "Stay ready for every session",
            bullets: [
                "Shared care updates",
                "Clear next steps",
                "Simple for patients and doctors"
            ],
            symbolName: "person.2.fill",
            accentColor: Palette.mutedBlue
        )
    ]

    private var currentIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStaticUI()
        
        applySlide(animated: false)
        addSwipeGestures()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    private func configureStaticUI() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor.systemCyan.withAlphaComponent(0.1).cgColor,
            UIColor.white.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        view.layer.insertSublayer(gradient, at: 0)


        skipButton.setTitleColor(Palette.mutedBlue, for: .normal)

        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = cardView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 28
        blurView.clipsToBounds = true
        
        let tintView = UIView(frame: cardView.bounds)
        tintView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        cardView.insertSubview(tintView, aboveSubview: blurView)

        cardView.insertSubview(blurView, at: 0)
        cardView.backgroundColor = .clear
        cardView.layer.cornerRadius = 28
        cardView.layer.cornerCurve = .continuous
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowRadius = 20
        cardView.layer.shadowOffset = CGSize(width: 0, height: 10)
        cardView.layer.borderWidth = 1.2
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor


        iconContainerView.layer.cornerCurve = .continuous
        iconContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        iconContainerView.layer.cornerRadius = 50
        

        nextButton.layer.cornerRadius = 22
        nextButton.layer.cornerCurve = .continuous
        nextButton.layer.masksToBounds = true

        topAccentView.layer.cornerRadius = 80
        bottomAccentView.layer.cornerRadius = 95

        topAccentView.backgroundColor = Palette.primaryCyan.withAlphaComponent(0.35)
        bottomAccentView.backgroundColor = Palette.actionBlue.withAlphaComponent(0.25)

        pageControl.numberOfPages = slides.count
        pageControl.currentPageIndicatorTintColor = Palette.actionBlue
        pageControl.pageIndicatorTintColor = Palette.primaryCyan.withAlphaComponent(0.22)
        
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
    }

    private func applySlide(animated: Bool) {

        let updateContent = {
            let slide = self.slides[self.currentIndex]

            // Title
            self.titleLabel.text = slide.title

            // Bullets
            self.bulletOneLabel.text = "• \(slide.bullets[0])"
            self.bulletTwoLabel.text = "• \(slide.bullets[1])"
            self.bulletThreeLabel.text = "• \(slide.bullets[2])"

            // Icon
            self.iconImageView.image = UIImage(systemName: slide.symbolName)
            self.iconImageView.tintColor = slide.accentColor

            // Icon Background
            self.iconContainerView.backgroundColor = slide.accentColor.withAlphaComponent(0.14)

            // Page Control
            self.pageControl.currentPage = self.currentIndex

            // Button
            let isLast = self.currentIndex == self.slides.count - 1
            self.nextButton.setTitle(isLast ? "Get Started" : "Continue", for: .normal)
            self.nextButton.backgroundColor = isLast ? Palette.actionBlue : Palette.primaryCyan
        }

        if animated {

            // Reset initial states
            titleLabel.alpha = 0
            titleLabel.transform = CGAffineTransform(translationX: 0, y: 20).scaledBy(x: 0.9, y: 0.9)

            bulletOneLabel.alpha = 0
            bulletTwoLabel.alpha = 0
            bulletThreeLabel.alpha = 0

            updateContent()

            // Animate TITLE (main focus)
            UIView.animate(
                withDuration: 0.45,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: []
            ) {
                self.titleLabel.alpha = 1
                self.titleLabel.transform = .identity
                self.view.layoutIfNeeded()
            }

            // Staggered bullets
            UIView.animate(withDuration: 0.3, delay: 0.2) {
                self.bulletOneLabel.alpha = 1
            }

            UIView.animate(withDuration: 0.3, delay: 0.3) {
                self.bulletTwoLabel.alpha = 1
            }

            UIView.animate(withDuration: 0.3, delay: 0.4) {
                self.bulletThreeLabel.alpha = 1
            }

        } else {
            updateContent()
        }
    }

    private func addSwipeGestures() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right

        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }

    @IBAction private func nextTapped(_ sender: UIButton) {
        if currentIndex == slides.count - 1 {
            finishOnboarding()
            return
        }

        currentIndex += 1
        applySlide(animated: true)
    }

    @IBAction private func skipTapped(_ sender: UIButton) {
        finishOnboarding()
    }

    @IBAction private func pageChanged(_ sender: UIPageControl) {
        currentIndex = sender.currentPage
        applySlide(animated: true)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left where currentIndex < slides.count - 1:
            currentIndex += 1
            applySlide(animated: true)
        case .right where currentIndex > 0:
            currentIndex -= 1
            applySlide(animated: true)
        default:
            break
        }
    }

    private func finishOnboarding() {
        if let onFinish {
            onFinish()
            return
        }

        if let navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}

private struct OnboardingSlide {
    let tag: String
    let title: String
    let bullets: [String]
    let symbolName: String
    let accentColor: UIColor
}

private enum Palette {
    static let primaryCyan = UIColor(red255: 0, green255: 192, blue255: 232)
    static let actionBlue = UIColor(red255: 59, green255: 138, blue255: 255)
    static let mutedBlue = UIColor(red255: 80, green255: 134, blue255: 198)
}

private extension UIColor {
    convenience init(red255: Int, green255: Int, blue255: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red255) / 255.0,
            green: CGFloat(green255) / 255.0,
            blue: CGFloat(blue255) / 255.0,
            alpha: alpha
        )
    }
}
