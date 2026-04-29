import UIKit

final class WellSyncOnboardingViewController: UIViewController {

    private var backgroundGradientLayer: CAGradientLayer?
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
    private var hasAnimatedInitialSlide = false
    private var isTransitioning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStaticUI()
        updateSlideContent()
        prepareSlideContentForEntrance()
        addSwipeGestures()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasAnimatedInitialSlide else { return }
        hasAnimatedInitialSlide = true
        applySlide(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer?.frame = view.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    private func configureStaticUI() {
        configureBackgroundGradient()

        skipButton.setTitleColor(Palette.mutedBlue, for: .normal)

        let blurEffect = UIBlurEffect(style: .systemThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = cardView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 28
        blurView.clipsToBounds = true
        
        let tintView = UIView(frame: cardView.bounds)
        tintView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let borderView = UIView(frame: cardView.bounds)
        borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        borderView.backgroundColor = .clear
        borderView.layer.cornerRadius = 28
        borderView.layer.cornerCurve = .continuous
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor.white.withAlphaComponent(0.42).cgColor
        borderView.isUserInteractionEnabled = false

        cardView.insertSubview(blurView, at: 0)
        cardView.insertSubview(tintView, aboveSubview: blurView)
        cardView.addSubview(borderView)
        cardView.backgroundColor = .clear
        cardView.layer.cornerRadius = 28
        cardView.layer.cornerCurve = .continuous
        cardView.clipsToBounds = true
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius = 22
        cardView.layer.shadowOffset = CGSize(width: 0, height: 14)
        cardView.layer.isDoubleSided = false


        iconContainerView.layer.cornerCurve = .continuous
        iconContainerView.backgroundColor = Palette.softBlue.withAlphaComponent(0.18)
        iconContainerView.layer.cornerRadius = 44
        iconContainerView.layer.borderWidth = 1
        iconContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        

        nextButton.layer.cornerRadius = 22
        nextButton.layer.cornerCurve = .continuous
        nextButton.layer.masksToBounds = true

        topAccentView.layer.cornerRadius = 80
        bottomAccentView.layer.cornerRadius = 95

        styleAccentCircle(topAccentView, tint: Palette.circleMint, fillAlpha: 0.08, borderAlpha: 0.28)
        styleAccentCircle(bottomAccentView, tint: Palette.circleBlue, fillAlpha: 0.10, borderAlpha: 0.18)

        pageControl.numberOfPages = slides.count
        pageControl.currentPageIndicatorTintColor = Palette.actionBlue
        pageControl.pageIndicatorTintColor = Palette.softBlue.withAlphaComponent(0.32)
        
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        [bulletOneLabel, bulletTwoLabel, bulletThreeLabel].forEach { label in
            label?.numberOfLines = 0
            label?.textAlignment = .left
        }
    }

    private func configureBackgroundGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            Palette.backgroundTop.cgColor,
            Palette.backgroundMid.cgColor,
            Palette.backgroundBottom.cgColor
        ]
        gradientLayer.locations = [0, 0.58, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        backgroundGradientLayer = gradientLayer
    }

    private func styleAccentCircle(_ orbView: UIView, tint: UIColor, fillAlpha: CGFloat, borderAlpha: CGFloat) {
        orbView.subviews.forEach { $0.removeFromSuperview() }
        orbView.layer.sublayers?.removeAll()
        orbView.backgroundColor = tint.withAlphaComponent(fillAlpha)
        orbView.layer.cornerCurve = .continuous
        orbView.layer.masksToBounds = true
        orbView.layer.borderWidth = 1
        orbView.layer.borderColor = UIColor.white.withAlphaComponent(borderAlpha).cgColor
    }

    private enum SlideDirection {
        case forward
        case backward
    }

    private func transitionToSlide(at newIndex: Int, direction: SlideDirection) {
        guard slides.indices.contains(newIndex) else { return }
        guard !isTransitioning else { return }
        guard newIndex != currentIndex else { return }

        isTransitioning = true
        view.isUserInteractionEnabled = false

        currentIndex = newIndex
        pageControl.currentPage = newIndex

        let transition: UIView.AnimationOptions = direction == .forward
            ? .transitionFlipFromRight
            : .transitionFlipFromLeft

        UIView.transition(
            with: cardView,
            duration: 0.42,
            options: [transition, .curveEaseInOut, .showHideTransitionViews, .allowAnimatedContent]
        ) {
            self.updateSlideContent()
            self.prepareSlideContentForEntrance()
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.animateSlideContentEntrance()
            self.view.isUserInteractionEnabled = true
            self.isTransitioning = false
        }
    }

    private func applySlide(animated: Bool) {
        updateSlideContent()

        if animated {
            animateSlideContentEntrance()
        } else {
            resetSlideContentAppearance()
        }
    }

    private func updateSlideContent() {
        let slide = slides[currentIndex]

        titleLabel.text = slide.title
        bulletOneLabel.attributedText = makeBulletText(slide.bullets[0])
        bulletTwoLabel.attributedText = makeBulletText(slide.bullets[1])
        bulletThreeLabel.attributedText = makeBulletText(slide.bullets[2])

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        iconImageView.image = UIImage(systemName: slide.symbolName, withConfiguration: iconConfig)
        iconImageView.tintColor = slide.accentColor
        iconContainerView.backgroundColor = slide.accentColor.withAlphaComponent(0.14)

        pageControl.currentPage = currentIndex

        let isLast = currentIndex == slides.count - 1
        nextButton.setTitle(isLast ? "Get Started" : "Continue", for: .normal)
        nextButton.backgroundColor = isLast ? Palette.actionBlue : Palette.softBlue
    }

    private func resetSlideContentAppearance() {
        iconContainerView.isHidden = false
        titleLabel.alpha = 1
        titleLabel.isHidden = false
        titleLabel.transform = .identity
        bulletOneLabel.alpha = 1
        bulletOneLabel.isHidden = false
        bulletOneLabel.transform = .identity
        bulletTwoLabel.alpha = 1
        bulletTwoLabel.isHidden = false
        bulletTwoLabel.transform = .identity
        bulletThreeLabel.alpha = 1
        bulletThreeLabel.isHidden = false
        bulletThreeLabel.transform = .identity
        iconContainerView.alpha = 1
        iconContainerView.transform = .identity
    }

    private func prepareSlideContentForEntrance() {
        iconContainerView.isHidden = true
        iconContainerView.alpha = 0
        iconContainerView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)

        titleLabel.alpha = 0
        titleLabel.isHidden = true
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 26).scaledBy(x: 0.92, y: 0.92)

        bulletOneLabel.alpha = 0
        bulletOneLabel.isHidden = true
        bulletOneLabel.transform = CGAffineTransform(translationX: 0, y: 10)
        bulletTwoLabel.alpha = 0
        bulletTwoLabel.isHidden = true
        bulletTwoLabel.transform = CGAffineTransform(translationX: 0, y: 10)
        bulletThreeLabel.alpha = 0
        bulletThreeLabel.isHidden = true
        bulletThreeLabel.transform = CGAffineTransform(translationX: 0, y: 10)
    }

    private func animateSlideContentEntrance() {
        prepareSlideContentForEntrance()

        iconContainerView.isHidden = false
        titleLabel.isHidden = false
        bulletOneLabel.isHidden = false
        bulletTwoLabel.isHidden = false
        bulletThreeLabel.isHidden = false

        UIView.animate(
            withDuration: 0.3,
            delay: 0.08,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.4,
            options: []
        ) {
            self.iconContainerView.alpha = 1
            self.iconContainerView.transform = .identity
        }

        UIView.animate(
            withDuration: 0.42,
            delay: 0.12,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.45,
            options: []
        ) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
            self.view.layoutIfNeeded()
        }

        UIView.animate(withDuration: 0.28, delay: 0.26) {
            self.bulletOneLabel.alpha = 1
            self.bulletOneLabel.transform = .identity
        }

        UIView.animate(withDuration: 0.28, delay: 0.36) {
            self.bulletTwoLabel.alpha = 1
            self.bulletTwoLabel.transform = .identity
        }

        UIView.animate(withDuration: 0.28, delay: 0.46) {
            self.bulletThreeLabel.alpha = 1
            self.bulletThreeLabel.transform = .identity
        }
    }

    private func makeBulletText(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 0
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.alignment = .left

        return NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .kern: 0.1
            ]
        )
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

        transitionToSlide(at: currentIndex + 1, direction: .forward)
    }

    @IBAction private func skipTapped(_ sender: UIButton) {
        finishOnboarding()
    }

    @IBAction private func pageChanged(_ sender: UIPageControl) {
        let newIndex = sender.currentPage
        let direction: SlideDirection = newIndex >= currentIndex ? .forward : .backward
        transitionToSlide(at: newIndex, direction: direction)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left where currentIndex < slides.count - 1:
            transitionToSlide(at: currentIndex + 1, direction: .forward)
        case .right where currentIndex > 0:
            transitionToSlide(at: currentIndex - 1, direction: .backward)
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
    static let primaryCyan = UIColor(red255: 117, green255: 208, blue255: 223)
    static let softBlue = UIColor(red255: 145, green255: 219, blue255: 230)
    static let actionBlue = UIColor(red255: 89, green255: 164, blue255: 208)
    static let mutedBlue = UIColor(red255: 119, green255: 159, blue255: 196)
    static let circleMint = UIColor(red255: 198, green255: 240, blue255: 237)
    static let circleBlue = UIColor(red255: 173, green255: 203, blue255: 224)
    static let backgroundTop = UIColor(red255: 143, green255: 210, blue255: 214)
    static let backgroundMid = UIColor(red255: 192, green255: 231, blue255: 233)
    static let backgroundBottom = UIColor(red255: 236, green255: 247, blue255: 246)
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
