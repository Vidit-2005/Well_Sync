import UIKit

// MARK: - Tag used to identify the gradient view
private let kGradientViewTag = 98712

// A view that automatically resizes its gradient layer when its bounds change.
class GlobalGradientBackgroundView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    init() {
        super.init(frame: .zero)
        tag = kGradientViewTag
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tag = kGradientViewTag
        setupGradient()
    }
    
    private func setupGradient() {
        let themeColor = UIColor(red: 113/255, green: 201/255, blue: 206/255, alpha: 1.0)
        
        gradientLayer.colors = [
            themeColor.withAlphaComponent(0.40).cgColor,
            themeColor.withAlphaComponent(0.00).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.7)
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isUserInteractionEnabled = false
    }
}

extension UIViewController {
    @objc static func swizzleGlobalBackground() {
        _ = swizzleGlobalBackgroundOnce
    }
    
    private static let swizzleGlobalBackgroundOnce: Void = {
        // Swizzle viewDidLoad to inject gradient
        let originalLoad = #selector(viewDidLoad)
        let swizzledLoad = #selector(swizzled_viewDidLoad_globalGradient)
        if let origM = class_getInstanceMethod(UIViewController.self, originalLoad),
           let swizM = class_getInstanceMethod(UIViewController.self, swizzledLoad) {
            method_exchangeImplementations(origM, swizM)
        }
        
        // Swizzle viewWillAppear to re-enforce transparent backgrounds
        // (handles subclasses that override viewDidLoad and set opaque backgrounds after super)
        let originalAppear = #selector(viewWillAppear(_:))
        let swizzledAppear = #selector(swizzled_viewWillAppear_globalGradient(_:))
        if let origM = class_getInstanceMethod(UIViewController.self, originalAppear),
           let swizM = class_getInstanceMethod(UIViewController.self, swizzledAppear) {
            method_exchangeImplementations(origM, swizM)
        }
    }()
    
    // MARK: - Helper: should this VC get the gradient?
    private var shouldApplyGlobalGradient: Bool {
        let className = String(describing: type(of: self))
        if className.hasPrefix("UI") || className.hasPrefix("_") { return false }
        if self is UINavigationController || self is UITabBarController ||
            self is UISplitViewController || self is UIAlertController ||
            self is UIPageViewController { return false }
        
        // Exclude specific view controllers that need a pure black background
        if className.contains("JournalImageViewController") { return false }
        
        return true
    }
    
    // MARK: - viewDidLoad swizzle: inject the gradient
    @objc func swizzled_viewDidLoad_globalGradient() {
        // Call the original viewDidLoad
        self.swizzled_viewDidLoad_globalGradient()
        
        guard shouldApplyGlobalGradient else { return }
        
        let gradientView = GlobalGradientBackgroundView()
        
        if let collectionVC = self as? UICollectionViewController {
            let bgContainer = UIView(frame: collectionVC.collectionView.bounds)
            bgContainer.backgroundColor = .systemBackground
            bgContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            gradientView.frame = bgContainer.bounds
            bgContainer.addSubview(gradientView)
            collectionVC.collectionView.backgroundView = bgContainer
            collectionVC.collectionView.backgroundColor = .clear
        } else if let tableVC = self as? UITableViewController {
            let bgContainer = UIView(frame: tableVC.tableView.bounds)
            bgContainer.backgroundColor = .systemBackground
            bgContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            gradientView.frame = bgContainer.bounds
            bgContainer.addSubview(gradientView)
            tableVC.tableView.backgroundView = bgContainer
            tableVC.tableView.backgroundColor = .clear
        } else {
            // Check if the first subview is a collection view or table view.
            // If it is, setting its backgroundView instead of inserting a subview at index 0
            // of the view controller's main view keeps the scroll view at index 0.
            // This is required for UIKit's large titles and collapsing navigation bar behaviors to work correctly.
            if let firstScrollView = self.view.subviews.first as? UIScrollView,
               (firstScrollView is UICollectionView || firstScrollView is UITableView) {
                
                let bgContainer = UIView(frame: firstScrollView.bounds)
                bgContainer.backgroundColor = .systemBackground
                bgContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                gradientView.frame = bgContainer.bounds
                bgContainer.addSubview(gradientView)
                
                if let cv = firstScrollView as? UICollectionView {
                    cv.backgroundView = bgContainer
                    cv.backgroundColor = .clear
                } else if let tv = firstScrollView as? UITableView {
                    tv.backgroundView = bgContainer
                    tv.backgroundColor = .clear
                }
            } else {
                if self.view.backgroundColor == nil || self.view.backgroundColor == .clear {
                    self.view.backgroundColor = .systemBackground
                }
                gradientView.frame = self.view.bounds
                self.view.insertSubview(gradientView, at: 0)
            }
            
            // Make any direct-child collection/table views transparent
            for subview in self.view.subviews {
                if let cv = subview as? UICollectionView {
                    cv.backgroundColor = .clear
                } else if let tv = subview as? UITableView {
                    tv.backgroundColor = .clear
                }
            }
        }
    }
    
    // MARK: - viewWillAppear swizzle: re-enforce clear backgrounds
    // This runs after the entire viewDidLoad chain (including subclass overrides) completes,
    // so it catches cases where a subclass sets an opaque backgroundColor after calling super.
    @objc func swizzled_viewWillAppear_globalGradient(_ animated: Bool) {
        // Call the original viewWillAppear
        self.swizzled_viewWillAppear_globalGradient(animated)
        
        guard shouldApplyGlobalGradient else { return }
        
        if let collectionVC = self as? UICollectionViewController {
            collectionVC.collectionView.backgroundColor = .clear
        } else if let tableVC = self as? UITableViewController {
            tableVC.tableView.backgroundColor = .clear
        } else {
            // Re-clear any direct-child collection/table views
            for subview in self.view.subviews {
                if let cv = subview as? UICollectionView {
                    cv.backgroundColor = .clear
                } else if let tv = subview as? UITableView {
                    tv.backgroundColor = .clear
                }
            }
        }
    }
}
