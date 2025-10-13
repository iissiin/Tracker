import Foundation

final class StatisticsCalculator {
    private let trackerRecordStore: TrackerRecordStoring
    private let trackerStore: TrackerStoring

    init(trackerRecordStore: TrackerRecordStoring, trackerStore: TrackerStoring) {
        self.trackerRecordStore = trackerRecordStore
        self.trackerStore = trackerStore
    }

    struct Stats {
        var bestPeriod: Int
        var idealDays: Int
        var completedTrackers: Int
        var averagePerDay: Int
    }

    func calculate() -> Stats {
        let records: [PersistentRecord]
        do {
            records = try trackerRecordStore.fetchAllRecords().sorted { $0.date < $1.date }
        } catch {
            print("Ошибка fetch записей: \(error)")
            return Stats(bestPeriod: 0, idealDays: 0, completedTrackers: 0, averagePerDay: 0)
        }

        guard !records.isEmpty else {
            return Stats(bestPeriod: 0, idealDays: 0, completedTrackers: 0, averagePerDay: 0)
        }

        let completed = records.count

        var maxStreak = 1
        var currentStreak = 1
        let calendar = Calendar.current
        for i in 1..<records.count {
            let prevDay = calendar.startOfDay(for: records[i-1].date)
            let currDay = calendar.startOfDay(for: records[i].date)
            if calendar.dateComponents([.day], from: prevDay, to: currDay).day == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        let uniqueDays = Set(records.map { calendar.startOfDay(for: $0.date) }).count
        let average = uniqueDays > 0 ? completed / uniqueDays : 0

        let allTrackersCount: Int
        do {
            allTrackersCount = try trackerStore.fetchAllTrackersCount()
        } catch {
            print("Ошибка подсчёта трекеров: \(error)")
            allTrackersCount = 0
        }
        var idealCount = 0
        let recordsByDay = Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
        for (_, dayRecords) in recordsByDay {
            if dayRecords.count == allTrackersCount {
                idealCount += 1
            }
        }

        return Stats(bestPeriod: maxStreak, idealDays: idealCount, completedTrackers: completed, averagePerDay: average)
    }
}
