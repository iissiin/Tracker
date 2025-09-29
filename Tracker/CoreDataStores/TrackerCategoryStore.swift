import Foundation
import CoreData

struct PersistentCategory {
    let title: String
    let trackers: [PersistentTracker]
}

protocol TrackerCategoryStoring {
    func addCategory(_ category: PersistentCategory) throws
    func fetchCategories() throws -> [PersistentCategory]
    func deleteCategory(title: String) throws
}

final class TrackerCategoryStore: NSObject, TrackerCategoryStoring {
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>?
    weak var delegate: TrackerCategoryStoreDelegate?
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<TrackerCategoryStoreUpdate.Move>?

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupDefaultCategory()
    }

    // MARK: - Setup
    private func setupFetchedResultsController() {
        guard fetchedResultsController == nil else {
            return
        }
        
        guard context.persistentStoreCoordinator != nil else {
            return
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "TrackerCategoryCoreData", in: context) else {
            return
        }
        
        let fetchRequest = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \TrackerCategoryCoreData.title, ascending: true)
        ]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController?.delegate = self
    }

    // MARK: - Public
    var categories: [PersistentCategory] {
        setupFetchedResultsController()
        guard let fetchedResultsController = fetchedResultsController else {
            return []
        }
        do {
            try fetchedResultsController.performFetch()
            return fetchedResultsController.fetchedObjects?.compactMap { self.category(from: $0) } ?? []
        } catch {
            return []
        }
    }

    func addCategory(_ category: PersistentCategory) throws {
        guard let categoryEntity = NSEntityDescription.entity(forEntityName: "TrackerCategoryCoreData", in: context) else {
            throw TrackerCategoryStoreError.fetchError
        }
        let categoryCoreData = TrackerCategoryCoreData(entity: categoryEntity, insertInto: context)
        categoryCoreData.title = category.title

        for tracker in category.trackers {
            guard let trackerEntity = NSEntityDescription.entity(forEntityName: "TrackerCoreData", in: context) else {
                throw TrackerCategoryStoreError.fetchError
            }
            let trackerCoreData = TrackerCoreData(entity: trackerEntity, insertInto: context)
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
        setupFetchedResultsController()
        guard let fetchedResultsController = fetchedResultsController else {
            return []
        }
        try fetchedResultsController.performFetch()
        return fetchedResultsController.fetchedObjects?.compactMap { self.category(from: $0) } ?? []
    }

    func deleteCategory(title: String) throws {
        let request = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        request.predicate = NSPredicate(format: "title == %@", title)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
        }
    }

    // MARK: - Private
    private func setupDefaultCategory() {
        do {
            let categories = try fetchCategories()
            if categories.isEmpty {
                let defaultCategory = PersistentCategory(title: "Default", trackers: [])
                try addCategory(defaultCategory)
            }
        } catch {}
    }
    
    private func category(from coreData: TrackerCategoryCoreData) -> PersistentCategory? {
        guard let title = coreData.title else {
            return nil
        }

        let trackers: [PersistentTracker] = (coreData.trackers as? Set<TrackerCoreData>)?.compactMap { coreData in
            guard
                let id = coreData.id,
                let name = coreData.name,
                let colorName = coreData.colorName,
                let emoji = coreData.emoji
            else {
                return nil
            }

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
        }
        .sorted { $0.name < $1.name } ?? []

        return PersistentCategory(title: title, trackers: trackers)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
        movedIndexes = Set<TrackerCategoryStoreUpdate.Move>()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let delegate = delegate else { return }
        delegate.store(
            self,
            didUpdate: TrackerCategoryStoreUpdate(
                insertedIndexes: insertedIndexes ?? IndexSet(),
                deletedIndexes: deletedIndexes ?? IndexSet(),
                updatedIndexes: updatedIndexes ?? IndexSet(),
                movedIndexes: movedIndexes ?? Set()
            )
        )
        insertedIndexes = nil
        deletedIndexes = nil
        updatedIndexes = nil
        movedIndexes = nil
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            guard let indexPath = newIndexPath else { return }
            insertedIndexes?.insert(indexPath.item)
        case .delete:
            guard let indexPath = indexPath else { return }
            deletedIndexes?.insert(indexPath.item)
        case .update:
            guard let indexPath = indexPath else { return }
            updatedIndexes?.insert(indexPath.item)
        case .move:
            guard let oldIndexPath = indexPath, let newIndexPath = newIndexPath else { return }
            movedIndexes?.insert(.init(oldIndex: oldIndexPath.item, newIndex: newIndexPath.item))
        @unknown default:
            break
        }
    }
}
