import UIKit
import CoreData

// DTO
struct PersistentTracker {
    let id: UUID
    let name: String
    let colorName: String
    let emoji: String
    let schedule: [Int]
    let categoryTitle: String
}

// Протокол
protocol TrackerStoring {
    func addNewTracker(_ tracker: PersistentTracker) throws
    func fetchTrackers() throws -> [PersistentTracker]
    func deleteTracker(_ id: UUID) throws
}

// Реализация
final class TrackerStore: TrackerStoring {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addNewTracker(_ tracker: PersistentTracker) throws {
        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.colorName = tracker.colorName
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.schedule = tracker.schedule as NSArray

        // ищем категорию по title
        if let categoryObject = try fetchCategory(by: tracker.categoryTitle) {
            trackerCoreData.category = categoryObject
        } else {
            // если категории нет — создаём новую
            let newCategory = TrackerCategoryCoreData(context: context)
            newCategory.title = tracker.categoryTitle
            trackerCoreData.category = newCategory
        }

        try context.save()
    }

    func fetchTrackers() throws -> [PersistentTracker] {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        let result = try context.fetch(request)
        return result.compactMap { coreData in
            // восстанавливаем schedule
            let schedule: [Int]
            if let arr = coreData.schedule as? [Int] {
                schedule = arr
            } else if let nsarr = coreData.schedule as? NSArray {
                schedule = nsarr.compactMap { ($0 as? NSNumber)?.intValue }
            } else {
                schedule = []
            }

            guard
                let id = coreData.id,
                let name = coreData.name,
                let colorName = coreData.colorName,
                let emoji = coreData.emoji,
                let categoryTitle = coreData.category?.title
            else { return nil }

            return PersistentTracker(
                id: id,
                name: name,
                colorName: colorName,
                emoji: emoji,
                schedule: schedule,
                categoryTitle: categoryTitle
            )
        }
    }

    func deleteTracker(_ id: UUID) throws {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
        }
    }

    // --- helper: поиск категории по title ---
    private func fetchCategory(by title: String) throws -> TrackerCategoryCoreData? {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
