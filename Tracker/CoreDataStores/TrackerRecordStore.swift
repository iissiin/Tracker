import Foundation
import CoreData

protocol TrackerRecordStoring {
    func addRecord(_ record: PersistentRecord) throws
    func fetchRecords() throws -> [PersistentRecord]
    func deleteRecord(id: UUID) throws
}

final class TrackerRecordStore: TrackerRecordStoring {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addRecord(_ record: PersistentRecord) throws {
        let recordCoreData = TrackerRecordCoreData(context: context)
        recordCoreData.id = record.id
        recordCoreData.date = record.date

        let trackerRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        trackerRequest.predicate = NSPredicate(format: "id == %@", record.trackerId as CVarArg)
        if let tracker = try context.fetch(trackerRequest).first {
            recordCoreData.tracker = tracker
        }

        try context.save()
    }

    func fetchRecords() throws -> [PersistentRecord] {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        let result = try context.fetch(request)

        return result.compactMap { coreData in
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

    func deleteRecord(id: UUID) throws {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
        }
    }
}

