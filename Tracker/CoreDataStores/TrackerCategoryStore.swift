import Foundation
import CoreData

struct PersistentCategory {
    let title: String
    let trackers: [PersistentTracker]
}

struct PersistentRecord {
    let id: UUID
    let date: Date
    let trackerId: UUID
}

protocol TrackerCategoryStoring {
    func addCategory(_ category: PersistentCategory) throws
    func fetchCategories() throws -> [PersistentCategory]
    func deleteCategory(title: String) throws
}

final class TrackerCategoryStore: TrackerCategoryStoring {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addCategory(_ category: PersistentCategory) throws {
        let categoryCoreData = TrackerCategoryCoreData(context: context)
        categoryCoreData.title = category.title

        // создаём связи с трекерами
        for tracker in category.trackers {
            let trackerCoreData = TrackerCoreData(context: context)
            trackerCoreData.id = tracker.id
            trackerCoreData.name = tracker.name
            trackerCoreData.colorName = tracker.colorName
            trackerCoreData.emoji = tracker.emoji
            trackerCoreData.schedule = tracker.schedule as NSArray
            trackerCoreData.category = categoryCoreData
        }

        try context.save()
    }

    func fetchCategories() throws -> [PersistentCategory] {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        let result = try context.fetch(request)

        return result.compactMap { categoryCoreData in
            guard let title = categoryCoreData.title else { return nil }

            let trackers: [PersistentTracker] = (categoryCoreData.trackers as? Set<TrackerCoreData>)?.compactMap { coreData in
                guard
                    let id = coreData.id,
                    let name = coreData.name,
                    let colorName = coreData.colorName,
                    let emoji = coreData.emoji
                else { return nil }

                let schedule: [Int]
                if let arr = coreData.schedule as? [Int] {
                    schedule = arr
                } else if let nsarr = coreData.schedule as? NSArray {
                    schedule = nsarr.compactMap { ($0 as? NSNumber)?.intValue }
                } else {
                    schedule = []
                }

                return PersistentTracker(
                    id: id,
                    name: name,
                    colorName: colorName,
                    emoji: emoji,
                    schedule: schedule,
                    categoryTitle: title
                )
            } ?? []

            return PersistentCategory(title: title, trackers: trackers)
        }
    }

    func deleteCategory(title: String) throws {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
        }
    }
}
