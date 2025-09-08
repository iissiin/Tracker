import Foundation
import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let trackersVC = TrackersViewController()
        trackersVC.tabBarItem = UITabBarItem(title: "Трекеры", image: UIImage(systemName: "record.circle"), tag: 0)
        
        let secondVC = StatisticsViewController()
        secondVC.tabBarItem = UITabBarItem(title: "Статистика", image: UIImage(systemName: "hare.fill"), tag: 1)
        
        viewControllers = [trackersVC, secondVC]
        
        setupTabBarAppearance()
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
