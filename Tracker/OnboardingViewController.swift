import UIKit

class OnboardingViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    private var timer: Timer?

    lazy var pages: [UIViewController] = {
        // MARK: - First page
        let firstPage = UIViewController()
        
        let imageView1 = UIImageView(image: UIImage(named: "onboardingBlue"))
        imageView1.contentMode = .scaleAspectFill
        imageView1.translatesAutoresizingMaskIntoConstraints = false
        firstPage.view.addSubview(imageView1)
        
        NSLayoutConstraint.activate([
            imageView1.topAnchor.constraint(equalTo: firstPage.view.topAnchor),
            imageView1.bottomAnchor.constraint(equalTo: firstPage.view.bottomAnchor),
            imageView1.leadingAnchor.constraint(equalTo: firstPage.view.leadingAnchor),
            imageView1.trailingAnchor.constraint(equalTo: firstPage.view.trailingAnchor)
        ])
        
        let label1 = UILabel()
        label1.textColor = UIColor(named: "YP_Black[day]")
        label1.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label1.numberOfLines = 0
        label1.lineBreakMode = .byWordWrapping
        label1.textAlignment = .center
        
        let paragraphStyle1 = NSMutableParagraphStyle()
        paragraphStyle1.lineSpacing = 6
        paragraphStyle1.alignment = .center
        label1.attributedText = NSMutableAttributedString(
            string: "Отслеживайте только то, что хотите",
            attributes: [.paragraphStyle: paragraphStyle1]
        )
        
        label1.translatesAutoresizingMaskIntoConstraints = false
        firstPage.view.addSubview(label1)
        
        // Констрейнты: 432 пикселя от верха экрана
        NSLayoutConstraint.activate([
            label1.leadingAnchor.constraint(equalTo: firstPage.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            label1.trailingAnchor.constraint(equalTo: firstPage.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            label1.topAnchor.constraint(equalTo: firstPage.view.safeAreaLayoutGuide.topAnchor, constant: 432)
        ])
        
        // MARK: - Second page
        let secondPage = UIViewController()
        
        let imageView2 = UIImageView(image: UIImage(named: "onboardingRed"))
        imageView2.contentMode = .scaleAspectFill
        imageView2.translatesAutoresizingMaskIntoConstraints = false
        secondPage.view.addSubview(imageView2)
        
        NSLayoutConstraint.activate([
            imageView2.topAnchor.constraint(equalTo: secondPage.view.topAnchor),
            imageView2.bottomAnchor.constraint(equalTo: secondPage.view.bottomAnchor),
            imageView2.leadingAnchor.constraint(equalTo: secondPage.view.leadingAnchor),
            imageView2.trailingAnchor.constraint(equalTo: secondPage.view.trailingAnchor)
        ])
        
        let label2 = UILabel()
        label2.textColor = UIColor(named: "YP_Black[day]")
        label2.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label2.numberOfLines = 0
        label2.lineBreakMode = .byWordWrapping
        label2.textAlignment = .center
        
        let paragraphStyle2 = NSMutableParagraphStyle()
        paragraphStyle2.lineSpacing = 6
        paragraphStyle2.alignment = .center
        label2.attributedText = NSMutableAttributedString(
            string: "Даже если это не литры воды и йога",
            attributes: [.paragraphStyle: paragraphStyle2]
        )
        
        label2.translatesAutoresizingMaskIntoConstraints = false
        secondPage.view.addSubview(label2)
        
        // Констрейнты: 432 пикселя от верха экрана
        NSLayoutConstraint.activate([
            label2.leadingAnchor.constraint(equalTo: secondPage.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            label2.trailingAnchor.constraint(equalTo: secondPage.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            label2.topAnchor.constraint(equalTo: secondPage.view.safeAreaLayoutGuide.topAnchor, constant: 432)
        ])
        
        return [firstPage, secondPage]
    }()
    
    // MARK: - Page control
    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        
        if let ypBackgroundColor = UIColor(named: "YP_Black[day]") {
            pageControl.currentPageIndicatorTintColor = ypBackgroundColor
            pageControl.pageIndicatorTintColor = ypBackgroundColor.withAlphaComponent(0.3)
        } else {
            pageControl.currentPageIndicatorTintColor = UIColor.black
            pageControl.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.3)
        }
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    // MARK: - Button container
    lazy var buttonContainer: UIView = {
        let view = UIView()
        view.layer.backgroundColor = UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 1).cgColor
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont(name: "SFPro-Medium", size: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.15
        paragraphStyle.alignment = .center
        label.attributedText = NSMutableAttributedString(
            string: "Вот это технологии!",
            attributes: [.paragraphStyle: paragraphStyle]
        )
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 162),
            label.heightAnchor.constraint(equalToConstant: 22)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleButtonTap))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
        
        return view
    }()
    
    // MARK: - Init
    override init(transitionStyle style: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [UIPageViewController.OptionsKey : Any]? = nil) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: false, completion: nil)
        }
        
        view.addSubview(pageControl)
        view.addSubview(buttonContainer)
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: -24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            buttonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            buttonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            buttonContainer.heightAnchor.constraint(equalToConstant: 60),
            buttonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -70)
        ])
        
        startAutoScroll()
    }
    
    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let current = self.viewControllers?.first,
               let currentIndex = self.pages.firstIndex(of: current),
               let next = self.dataSource?.pageViewController(self, viewControllerAfter: current) {
                self.setViewControllers([next], direction: .forward, animated: true, completion: nil)
                let nextIndex = (currentIndex + 1) % self.pages.count
                self.pageControl.currentPage = nextIndex
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
    
    // MARK: - UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        return previousIndex >= 0 ? pages[previousIndex] : pages.last
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        return nextIndex < pages.count ? pages[nextIndex] : pages.first
    }
    
    // MARK: - UIPageViewControllerDelegate
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
    
    // MARK: - Actions
    @objc private func handleButtonTap() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let trackerStore = TrackerStore(context: context)
        let trackerCategoryStore = TrackerCategoryStore(context: context)
        let trackerRecordStore = TrackerRecordStore(context: context)
        
        let trackersVC = TrackersViewController(
            trackerStore: trackerStore,
            trackerCategoryStore: trackerCategoryStore,
            trackerRecordStore: trackerRecordStore
        )
        
        let statisticsVC = StatisticsViewController()
        let tabBarController = TabBarController(trackersVC: trackersVC, statisticsVC: statisticsVC)
        
        UIView.transition(with: view.window!, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.view.window?.rootViewController = tabBarController
        })
    }
}
