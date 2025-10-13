import UIKit
import CoreData

struct PersistentTracker {
    let id: UUID
    let name: String
    let colorName: String
    let emoji: String
    let schedule: [Int]
    let categoryTitle: String
}

protocol TrackerStoring {
    func addNewTracker(_ tracker: PersistentTracker) throws
    func fetchTrackers() throws -> [PersistentTracker]
    func deleteTracker(_ id: UUID) throws
    func updateTracker(_ tracker: PersistentTracker) throws
    func fetchAllTrackersCount() throws -> Int
}

final class TrackerStore: NSObject, TrackerStoring {
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>?
    weak var delegate: TrackerStoreDelegate?
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<TrackerStoreUpdate.Move>?

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
    }

    // MARK: - Setup
    private func setupFetchedResultsController() {
        guard fetchedResultsController == nil else { return }
        guard context.persistentStoreCoordinator != nil else { return }
        guard let entity = NSEntityDescription.entity(forEntityName: "TrackerCoreData", in: context) else { return }
        
        let fetchRequest = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerCoreData.name, ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController?.delegate = self
    }

    // MARK: - Public
    var trackers: [PersistentTracker] {
        setupFetchedResultsController()
        guard let fetchedResultsController = fetchedResultsController else { return [] }
        do {
            try fetchedResultsController.performFetch()
            return fetchedResultsController.fetchedObjects?.compactMap { self.tracker(from: $0) } ?? []
        } catch {
            print("Ошибка получения трекеров: \(error)")
            return []
        }
    }

    func addNewTracker(_ tracker: PersistentTracker) throws {
        guard !tracker.categoryTitle.isEmpty else {
            throw TrackerStoreError.decodingError
        }
        
        guard let categoryObject = try fetchCategory(by: tracker.categoryTitle) else {
            throw TrackerStoreError.decodingError
        }
        
        let trackerCoreData = TrackerCoreData(context: context)
        updateExistingTracker(trackerCoreData, with: tracker)
        trackerCoreData.category = categoryObject
        
        try context.save()
    }

    func fetchTrackers() throws -> [PersistentTracker] {
        setupFetchedResultsController()
        guard let fetchedResultsController = fetchedResultsController else { return [] }
        try fetchedResultsController.performFetch()
        return fetchedResultsController.fetchedObjects?.compactMap { self.tracker(from: $0) } ?? []
    }

    func deleteTracker(_ id: UUID) throws {
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
        }
    }
    
    func updateTracker(_ tracker: PersistentTracker) throws {
        guard !tracker.categoryTitle.isEmpty else {
            throw TrackerStoreError.decodingError
        }
        
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        guard let trackerCoreData = try context.fetch(request).first else {
            throw TrackerStoreError.fetchError
        }
        
        guard let categoryObject = try fetchCategory(by: tracker.categoryTitle) else {
            throw TrackerStoreError.decodingError
        }
        
        updateExistingTracker(trackerCoreData, with: tracker)
        trackerCoreData.category = categoryObject
        
        try context.save()
    }
    
    func fetchAllTrackersCount() throws -> Int {
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        return try context.count(for: request)
    }

    // MARK: - Private
    private func fetchCategory(by title: String) throws -> TrackerCategoryCoreData? {
        let request = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        request.predicate = NSPredicate(format: "title == %@", title)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func tracker(from coreData: TrackerCoreData) -> PersistentTracker? {
        guard
            let id = coreData.id,
            let name = coreData.name,
            let colorName = coreData.colorName,
            let emoji = coreData.emoji,
            let categoryTitle = coreData.category?.title
        else {
            print("Ошибка: Неверные данные трекера")
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
            categoryTitle: categoryTitle
        )
    }

    private func updateExistingTracker(_ trackerCoreData: TrackerCoreData, with tracker: PersistentTracker) {
        trackerCoreData.id = tracker.id
        trackerCoreData.name = tracker.name
        trackerCoreData.colorName = tracker.colorName
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.schedule = tracker.schedule as NSArray
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
        movedIndexes = Set<TrackerStoreUpdate.Move>()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let delegate = delegate else { return }
        delegate.store(
            self,
            didUpdate: TrackerStoreUpdate(
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
