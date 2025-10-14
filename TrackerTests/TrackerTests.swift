import XCTest
import SnapshotTesting
import CoreData
@testable import Tracker

final class TrackerTests: XCTestCase {
    
    var viewController: TrackersViewController!
    var persistentContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        
        persistentContainer = NSPersistentContainer(name: "TrackerModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Ошибка инициализации in-memory контейнера: \(error)")
            }
        }
        
        let context = persistentContainer.viewContext
        let trackerStore = TrackerStore(context: context)
        let trackerCategoryStore = TrackerCategoryStore(context: context)
        let trackerRecordStore = TrackerRecordStore(context: context)
        
        viewController = TrackersViewController(
            trackerStore: trackerStore,
            trackerCategoryStore: trackerCategoryStore,
            trackerRecordStore: trackerRecordStore
        )
    }
    
    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        persistentContainer = nil
        viewController = nil
        super.tearDown()
    }
    
    private func prepareForSnapshot() {
        viewController.loadViewIfNeeded()
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        viewController.view.frame = CGRect(origin: .zero, size: CGSize(width: 390, height: 844)) // iPhone 13 Pro
    }
    
    func testTrackersViewControllerLightTheme() {
        viewController.overrideUserInterfaceStyle = .light
        prepareForSnapshot()
        
        assertSnapshot(
            of: viewController,
            as: .image(on: .iPhone13Pro, traits: .init(userInterfaceStyle: .light)),
            named: "TrackersViewController_Light",
            record: true
        )
    }
    
    func testTrackersViewControllerDarkTheme() {
        viewController.overrideUserInterfaceStyle = .dark
        prepareForSnapshot()
        
        assertSnapshot(
            of: viewController,
            as: .image(on: .iPhone13Pro, traits: .init(userInterfaceStyle: .dark)),
            named: "TrackersViewController_Dark",
            record: true
        )
    }
}
