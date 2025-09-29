import UIKit

final class TabBarController: UITabBarController {

    init(
        trackersVC: UIViewController,
        statisticsVC: UIViewController
    ) {
        super.init(nibName: nil, bundle: nil)
        
        trackersVC.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle"),
            tag: 0
        )
        
        statisticsVC.tabBarItem = UITabBarItem(
            title: "Статистика",
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
        appearance.backgroundColor = UIColor(named: "YP_White")
        appearance.shadowColor = UIColor.separator
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}
