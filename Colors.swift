import UIKit

enum AppColors {
    static var background: UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
            default:
                return .white
            }
        }
    }
    
    static var labelPrimary: UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return .white
            default:
                return .black
            }
        }
    }
    
    static var labelSecondary: UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
            default:
                return .darkGray
            }
        }
    }
    
    static var searchBarBackground: UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1)
            default:
                return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
            }
        }
    }
    
    static var buttonPlus: UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return .white
            default:
                return .black
            }
        }
    }
    
    static var sectionHeaderText: UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return .white
            default:
                return .black
            }
        }
    }
    
    static var datePickerBackground: UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return .white
            default:
                return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
            }
        }
    }

    static var datePickerText: UIColor {
        UIColor { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return .black
            default:
                return UIColor.darkGray
            }
        }
    }
    
    static var tabBarBackground: UIColor {
        UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 26/255, green: 27/255, blue: 34/255, alpha: 1)
            } else {
                return UIColor(named: "YP_White") ?? .white
            }
        }
    }
    
    
}
