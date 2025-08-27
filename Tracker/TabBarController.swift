import Foundation
import UIKit

final class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let trackersVC = TrackersViewController()
        trackersVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "record.circle"), tag: 0)
        
        let secondVC = StatisticsViewController()
        secondVC.tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "hare.fill"), tag: 1)
        
        viewControllers = [trackersVC, secondVC]
    }
}
