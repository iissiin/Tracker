import Foundation
import UIKit

struct TrackerRecord: Hashable {
    let id: UUID
    let date: Date
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(id)
        hasher.combine(Calendar.current.startOfDay(for: date))
    }

    static func == (lhs: TrackerRecord, rhs: TrackerRecord) -> Bool {
        lhs.id == rhs.id &&
        Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)
    }
}
