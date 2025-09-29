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
        print("TrackerStore: Инициализирован с context = \(context)")
    }

    // MARK: - Setup
    private func setupFetchedResultsController() {
        guard fetchedResultsController == nil else {
            print("TrackerStore: fetchedResultsController уже инициализирован")
            return
        }
        
        // Проверяем, валиден ли context
        guard context.persistentStoreCoordinator != nil else {
            print("TrackerStore: Ошибка: context.persistentStoreCoordinator is nil")
            return
        }
        
        // Проверяем доступные сущности
        let entities = context.persistentStoreCoordinator?.managedObjectModel.entities.map { $0.name ?? "Unknown" }
        print("TrackerStore: Доступные сущности в модели данных: \(entities ?? [])")
        
        guard let entity = NSEntityDescription.entity(forEntityName: "TrackerCoreData", in: context) else {
            print("TrackerStore: Ошибка: Не найдена сущность TrackerCoreData")
            return
        }
        
        let fetchRequest = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \TrackerCoreData.name, ascending: true)
        ]
        
        print("TrackerStore: fetchRequest = \(fetchRequest), context = \(context)")
        
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
        guard let fetchedResultsController = fetchedResultsController else {
            print("TrackerStore: Ошибка: fetchedResultsController не инициализирован")
            return []
        }
        do {
            try fetchedResultsController.performFetch()
            return fetchedResultsController.fetchedObjects?.compactMap { self.tracker(from: $0) } ?? []
        } catch {
            print("TrackerStore: Ошибка при выполнении запроса трекеров: \(error)")
            return []
        }
    }

    func addNewTracker(_ tracker: PersistentTracker) throws {
        let trackerCoreData = TrackerCoreData(context: context)
        updateExistingTracker(trackerCoreData, with: tracker)
        
        // Проверяем, существует ли указанная категория, если нет — используем "Default"
        let categoryTitle = tracker.categoryTitle.isEmpty ? "Default" : tracker.categoryTitle
        if let categoryObject = try fetchCategory(by: categoryTitle) {
            trackerCoreData.category = categoryObject
        } else {
            let newCategory = TrackerCategoryCoreData(context: context)
            newCategory.title = categoryTitle
            trackerCoreData.category = newCategory
            print("TrackerStore: Создана новая категория \(categoryTitle) для трекера")
        }
        try context.save()
        print("TrackerStore: Трекер \(tracker.name) добавлен в категорию \(categoryTitle)")
    }

    func fetchTrackers() throws -> [PersistentTracker] {
        setupFetchedResultsController()
        guard let fetchedResultsController = fetchedResultsController else {
            print("TrackerStore: Ошибка: fetchedResultsController не инициализирован")
            return []
        }
        try fetchedResultsController.performFetch()
        return fetchedResultsController.fetchedObjects?.compactMap { self.tracker(from: $0) } ?? []
    }

    func deleteTracker(_ id: UUID) throws {
        let request = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
            print("TrackerStore: Трекер с id \(id) удален")
        }
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
            let emoji = coreData.emoji
        else {
            print("TrackerStore: Ошибка: Неверные данные трекера")
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

        // потом нормально сдлетаь категории
        let categoryTitle = coreData.category?.title ?? "Default"

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
