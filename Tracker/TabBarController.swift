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
    }
}
