import UIKit

final class TabBarController: UITabBarController {

    init(
        trackersVC: UIViewController,
        statisticsVC: UIViewController
    ) {
        super.init(nibName: nil, bundle: nil)
        
        trackersVC.tabBarItem = UITabBarItem(
            title: Localization.trackersTitle,
            image: UIImage(systemName: "record.circle"),
            tag: 0
        )
        
        statisticsVC.tabBarItem = UITabBarItem(
            title: Localization.statisticsTitle,
            image: UIImage(systemName: "hare.fill"),
            tag: 1
        )
        
        viewControllers = [trackersVC, statisticsVC]
        setupTabBarAppearance()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не используется. Используй init(trackersVC:statisticsVC:)")
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        appearance.backgroundColor = AppColors.tabBarBackground
        appearance.shadowColor = UIColor.separator
        
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .gray
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}
