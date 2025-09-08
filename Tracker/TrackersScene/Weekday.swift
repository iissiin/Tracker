import Foundation
import UIKit

enum Weekday: Int, CaseIterable, Codable, Hashable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        Weekday(rawValue: calendar.component(.weekday, from: date))!
    }

    var shortSymbol: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
        }
    }
    
    var fullName: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }
}
