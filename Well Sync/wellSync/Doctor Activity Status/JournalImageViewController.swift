//
//  JournalImageViewController.swift
//  wellSync
//
//  Created by Rishika Mittal on 02/04/26.
//

//  JournalImageViewController.swift
//  wellSync

import UIKit

class JournalImageViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var scrollView: UIScrollView!          // horizontal pager
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var summaryButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!        // NEW

    // MARK: - Properties
    var journalEntry: JournalEntry?

    /// One inner zoom-scroll-view per image page
    private var pageScrollViews: [UIScrollView] = []
    /// Loaded images, indexed by page
    private var loadedImages: [Int: UIImage] = [:]
    /// Track which pages have finished loading
    private var loadedPageCount = 0

    // MARK: - Computed helpers
    private var paths: [String] { journalEntry?.uploadPaths ?? [] }
    private var currentPage: Int { Int(round(scrollView.contentOffset.x / scrollView.bounds.width)) }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOuterScrollView()
        setupNavigationBar()
        setupSummaryButton()
        setupPageControl()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutPages()          // recalculate frames when bounds are known
    }

    // MARK: - Setup

    private func setupOuterScrollView() {
        // Outer scroll view scrolls HORIZONTALLY between pages
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.bounces = false
    }

    private func setupNavigationBar() {
        title = journalEntry?.title ?? "Journal"
        navigationController?.navigationBar.tintColor = .white
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupSummaryButton() {
        summaryButton.isHidden = true
        summaryButton.tintColor = .white
        summaryButton.setTitleColor(.white, for: .normal)
    }

    private func setupPageControl() {
        let count = paths.count
        pageControl.numberOfPages = count
        pageControl.currentPage = 0
        pageControl.isHidden = count <= 1   // hide dots for single image
    }

    // MARK: - Page Layout
    // Called after bounds are known (viewDidLayoutSubviews).
    // Creates one inner UIScrollView + UIImageView per image path
    // if they haven't been created yet, then loads images.

    private func layoutPages() {
        guard !paths.isEmpty else { showPlaceholder(); return }

        let pageWidth  = scrollView.bounds.width
        let pageHeight = scrollView.bounds.height

        // Only build pages once
        if pageScrollViews.isEmpty {
            for i in 0..<paths.count {
                // --- inner zoom scroll view ---
                let inner = UIScrollView()
                inner.minimumZoomScale = 1.0
                inner.maximumZoomScale = 5.0
                inner.showsHorizontalScrollIndicator = false
                inner.showsVerticalScrollIndicator = false
                inner.backgroundColor = .black
                inner.delegate = self
                inner.tag = i           // use tag to identify page

                // --- image view inside inner scroll view ---
                let iv = UIImageView()
                iv.contentMode = .scaleAspectFit
                iv.tag = 100 + i        // unique tag to retrieve later
                inner.addSubview(iv)

                // --- double-tap gesture on each page ---
                let doubleTap = UITapGestureRecognizer(target: self,
                                                       action: #selector(handleDoubleTap(_:)))
                doubleTap.numberOfTapsRequired = 2
                inner.addGestureRecognizer(doubleTap)

                scrollView.addSubview(inner)
                pageScrollViews.append(inner)
            }

            // Start loading all images concurrently
            loadAllImages()
        }

        // Update frames (also called on rotation)
        scrollView.contentSize = CGSize(width: pageWidth * CGFloat(paths.count),
                                        height: pageHeight)
        for (i, inner) in pageScrollViews.enumerated() {
            inner.frame = CGRect(x: pageWidth * CGFloat(i),
                                 y: 0,
                                 width: pageWidth,
                                 height: pageHeight)
            // Refit image inside this page
            if let iv = inner.viewWithTag(100 + i) as? UIImageView, iv.image != nil {
                fitImage(in: inner, imageView: iv)
            }
        }
    }

    // MARK: - Image Fitting (per page)

    private func fitImage(in innerScroll: UIScrollView, imageView: UIImageView) {
        guard let image = imageView.image else { return }

        let available = innerScroll.bounds.size
        let wScale = available.width  / image.size.width
        let hScale = available.height / image.size.height
        let scale  = min(wScale, hScale)

        let fw = image.size.width  * scale
        let fh = image.size.height * scale

        imageView.frame = CGRect(
            x: (available.width  - fw) / 2,
            y: (available.height - fh) / 2,
            width: fw,
            height: fh
        )
        innerScroll.contentSize = available
        innerScroll.minimumZoomScale = 1.0
        innerScroll.maximumZoomScale = 5.0
        innerScroll.zoomScale = 1.0
    }

    // MARK: - Image Loading

    private func loadAllImages() {
        guard !paths.isEmpty else { return }

        loadingIndicator.startAnimating()
        summaryButton.isHidden = true
        loadedPageCount = 0

        for (i, path) in paths.enumerated() {
            Task {
                do {
                    let data  = try await AccessSupabase.shared.downloadFile(path: path)
                    let image = UIImage(data: data)
                    await MainActor.run {
                        self.imageDidLoad(image, at: i)
                    }
                } catch {
                    await MainActor.run {
                        self.imageDidLoad(nil, at: i)   // show placeholder for failed page
                    }
                }
            }
        }
    }

    private func imageDidLoad(_ image: UIImage?, at index: Int) {
        guard index < pageScrollViews.count else { return }

        let inner = pageScrollViews[index]
        if let iv = inner.viewWithTag(100 + index) as? UIImageView {
            if let image {
                iv.image = image
                loadedImages[index] = image
            } else {
                iv.image = UIImage(systemName: "photo.fill")
                iv.tintColor = .systemGray
            }
            fitImage(in: inner, imageView: iv)
        }

        loadedPageCount += 1
        if loadedPageCount == paths.count {
            // All pages done — hide spinner, show button
            loadingIndicator.stopAnimating()
            summaryButton.isHidden = false
        }
    }

    private func showPlaceholder() {
        loadingIndicator.stopAnimating()
        summaryButton.isHidden = false
    }

    // MARK: - UIScrollViewDelegate

    /// Tells each inner scroll view which UIImageView to zoom
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // scrollView.tag == page index (set above)
        guard scrollView != self.scrollView else { return nil }
        return scrollView.viewWithTag(100 + scrollView.tag)
    }

    /// Re-center image after zoom
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard scrollView != self.scrollView,
              let iv = scrollView.viewWithTag(100 + scrollView.tag) else { return }
        let offsetX = max((scrollView.bounds.width  - scrollView.contentSize.width)  / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        iv.center = CGPoint(
            x: scrollView.contentSize.width  / 2 + offsetX,
            y: scrollView.contentSize.height / 2 + offsetY
        )
    }

    /// Update page control dots when the outer pager scrolls
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        pageControl.currentPage = currentPage
    }

    // MARK: - Double Tap Zoom

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let inner = gesture.view as? UIScrollView,
              let iv = inner.viewWithTag(100 + inner.tag) else { return }
        if inner.zoomScale > 1.0 {
            inner.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: iv)
            let rect  = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
            inner.zoom(to: rect, animated: true)
        }
    }

    // MARK: - Summary Action

    @IBAction func summaryTapped(_ sender: UIButton) {
        // Use the image from the currently visible page
        let image = loadedImages[currentPage] ?? UIImage(systemName: "photo.fill")!

        let sb = UIStoryboard(name: "JournalImageView", bundle: nil)
        let summaryVC = sb.instantiateViewController(withIdentifier: "ImageSummarySheetViewController")
                        as! ImageSummarySheetViewController
        summaryVC.image = image
        summaryVC.entryTitle = journalEntry?.title ?? "Journal Entry"

        if let sheet = summaryVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(summaryVC, animated: true)
    }
}
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupNavigationBar()
//        loadImage()
//    }
//    
//    // MARK: - Setup
//    
//    private func setupUI() {
//        view.backgroundColor = .black
//        
//        scrollView.frame = view.bounds
//        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        scrollView.delegate = self
//        view.addSubview(scrollView)
//        
//        imageView.frame = scrollView.bounds
//        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        imageView.contentMode = .scaleAspectFit
//        scrollView.addSubview(imageView)
//        
//        // Loading
//        view.addSubview(loadingIndicator)
//        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//        ])
//        
//        // Summary button
//        view.addSubview(summaryButton)
//        summaryButton.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            summaryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            summaryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
//        ])
//        summaryButton.addTarget(self, action: #selector(summaryTapped), for: .touchUpInside)
//        
//        // Double-tap to zoom
//        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
//        doubleTap.numberOfTapsRequired = 2
//        scrollView.addGestureRecognizer(doubleTap)
//    }
//    
//    private func setupNavigationBar() {
//        navigationController?.navigationBar.tintColor = .white
//        navigationController?.navigationBar.barStyle = .black
//        
//        // Transparent nav bar over black image
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithTransparentBackground()
//        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//        navigationController?.navigationBar.standardAppearance = appearance
//        navigationController?.navigationBar.scrollEdgeAppearance = appearance
//        
//        title = journalEntry?.title ?? "Journal"
//    }
//    
//    // MARK: - Image Loading
//    
//    private func loadImage() {
//        // If image already passed directly, use it
//        if let image = image {
//            imageView.image = image
//            return
//        }
//        
//        // Otherwise load from Supabase uploadPath
//        guard let path = journalEntry?.uploadPath else {
//            showPlaceholder()
//            return
//        }
//        
//        loadingIndicator.startAnimating()
//        summaryButton.isHidden = true
//        
//        Task {
//            do {
//                let imageData = try await AccessSupabase.shared.downloadFile(path: path)
//                let loadedImage = UIImage(data: imageData)
//                
//                DispatchQueue.main.async {
//                    self.loadingIndicator.stopAnimating()
//                    self.imageView.image = loadedImage
//                    self.image = loadedImage
//                    self.fitImageInScrollView()  // ← ADD THIS
//                    self.summaryButton.isHidden = false
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.loadingIndicator.stopAnimating()
//                    self.showPlaceholder()
//                    print("Failed to load image: \(error)")
//                }
//            }
//        }
//    }
//    
//    private func showPlaceholder() {
//        imageView.image = UIImage(systemName: "photo.fill")
//        imageView.tintColor = .systemGray
//        summaryButton.isHidden = false
//    }
//    
//    // MARK: - Actions
//    
//    @IBAction func summaryTapped(_ sender: UIButton) {
//        guard let image = imageView.image else { return }
//        
//        let summaryVC = ImageSummarySheetViewController()
//        summaryVC.image = image
//        summaryVC.entryTitle = journalEntry?.title ?? "Journal Entry"
//        
//        // Half-screen sheet
//        if let sheet = summaryVC.sheetPresentationController {
//            sheet.detents = [.medium(), .large()]
//            sheet.prefersGrabberVisible = true
//            sheet.preferredCornerRadius = 24
//        }
//        
//        present(summaryVC, animated: true)
//    }
////    @objc private func summaryTapped() {
////        guard let image = imageView.image else { return }
////        
////        let summaryVC = ImageSummarySheetViewController()
////        summaryVC.image = image
////        summaryVC.entryTitle = journalEntry?.title ?? "Journal Entry"
////        
////        // Half-screen sheet
////        if let sheet = summaryVC.sheetPresentationController {
////            sheet.detents = [.medium(), .large()]
////            sheet.prefersGrabberVisible = true
////            sheet.preferredCornerRadius = 24
////        }
////        
////        present(summaryVC, animated: true)
////    }
//    
//    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
//        if scrollView.zoomScale > 1.0 {
//            scrollView.setZoomScale(1.0, animated: true)
//        } else {
//            let point = gesture.location(in: imageView)
//            let rect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
//            scrollView.zoom(to: rect, animated: true)
//        }
//    }
//    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
//        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
//        imageView.center = CGPoint(
//            x: scrollView.contentSize.width / 2 + offsetX,
//            y: scrollView.contentSize.height / 2 + offsetY
//        )
//    }
//    // MARK: - UIScrollViewDelegate
//    
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return imageView
//    }
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        scrollView.frame = view.bounds
//        fitImageInScrollView()
//    }
//    private func fitImageInScrollView() {
//        guard let image = imageView.image else { return }
//        
//        let scrollSize = scrollView.bounds.size
//        let imageSize = image.size
//        
//        // Calculate scale to fit image within screen
//        let widthScale = scrollSize.width / imageSize.width
//        let heightScale = scrollSize.height / imageSize.height
//        let scale = min(widthScale, heightScale)
//        
//        // Size the imageView to the scaled image size
//        let fittedWidth = imageSize.width * scale
//        let fittedHeight = imageSize.height * scale
//        
//        imageView.frame = CGRect(
//            x: (scrollSize.width - fittedWidth) / 2,   // center horizontally
//            y: (scrollSize.height - fittedHeight) / 2,  // center vertically
//            width: fittedWidth,
//            height: fittedHeight
//        )
//        
//        scrollView.contentSize = scrollSize
//        scrollView.minimumZoomScale = 1.0
//        scrollView.maximumZoomScale = 5.0
//        scrollView.zoomScale = 1.0
//    }
//}
