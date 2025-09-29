import Foundation
import CoreData

struct PersistentRecord {
    let id: UUID
    let date: Date
    let trackerId: UUID
}

protocol TrackerRecordStoring {
    func addRecord(_ record: PersistentRecord) throws
    func fetchRecords() throws -> [PersistentRecord]
    func deleteRecord(id: UUID) throws
}

final class TrackerRecordStore: NSObject, TrackerRecordStoring {
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>?
    weak var delegate: TrackerRecordStoreDelegate?
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    private var updatedIndexes: IndexSet?
    private var movedIndexes: Set<TrackerRecordStoreUpdate.Move>?

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
    }

    // MARK: - Setup
    private func setupFetchedResultsController() {
        guard fetchedResultsController == nil else { return }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "TrackerRecordCoreData", in: context) else {
            print("Ошибка: Не найдена сущность TrackerRecordCoreData в модели данных")
            return
        }
        
        let fetchRequest = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
        fetchRequest.entity = entity
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: false)
        ]
        
        print("TrackerRecordStore: fetchRequest = \(fetchRequest), context = \(context)")
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController?.delegate = self
    }

    // MARK: - Public
    var records: [PersistentRecord] {
        setupFetchedResultsController()
        guard let fetchedResultsController = fetchedResultsController else { return [] }
        do {
            try fetchedResultsController.performFetch()
            return fetchedResultsController.fetchedObjects?.compactMap { self.record(from: $0) } ?? []
        } catch {
            print("Ошибка при выполнении запроса записей: \(error)")
            return []
        }
    }

    func addRecord(_ record: PersistentRecord) throws {
        let recordCoreData = TrackerRecordCoreData(context: context)
        recordCoreData.id = record.id
        recordCoreData.date = record.date

        let trackerRequest = NSFetchRequest<TrackerCoreData>(entityName: "TrackerCoreData")
        trackerRequest.predicate = NSPredicate(format: "id == %@", record.trackerId as CVarArg)
        if let tracker = try context.fetch(trackerRequest).first {
            recordCoreData.tracker = tracker
        }

        try context.save()
    }

    func fetchRecords() throws -> [PersistentRecord] {
        setupFetchedResultsController()
        guard let fetchedResultsController = fetchedResultsController else {
            print("Ошибка: fetchedResultsController не инициализирован")
            return []
        }
        try fetchedResultsController.performFetch()
        return fetchedResultsController.fetchedObjects?.compactMap { self.record(from: $0) } ?? []
    }

    func deleteRecord(id: UUID) throws {
        let request = NSFetchRequest<TrackerRecordCoreData>(entityName: "TrackerRecordCoreData")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
        }
    }

    // MARK: - Private
    private func record(from coreData: TrackerRecordCoreData) -> PersistentRecord? {
        guard
            let id = coreData.id,
            let date = coreData.date,
            let trackerId = coreData.tracker?.id
        else { return nil }

        return PersistentRecord(
            id: id,
            date: date,
            trackerId: trackerId
        )
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
        updatedIndexes = IndexSet()
        movedIndexes = Set<TrackerRecordStoreUpdate.Move>()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let delegate = delegate else { return }
        delegate.store(
            self,
            didUpdate: TrackerRecordStoreUpdate(
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
