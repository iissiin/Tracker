import Foundation
import UIKit

enum Weekday: Int, CaseIterable, Codable, Hashable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        Weekday(rawValue: calendar.component(.weekday, from: date))!
    }

    var shortSymbol: String {
        Localization.weekdayShortName(self)
    }
    
    var fullName: String {
        Localization.weekdayFullName(self)
    }
}
