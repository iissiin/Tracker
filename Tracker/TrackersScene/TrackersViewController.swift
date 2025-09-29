import UIKit

final class TrackersViewController: UIViewController, UISearchBarDelegate {
    
    // MARK: - Хранение данных (через абстракции)
    private let trackerStore: TrackerStoring
    private let trackerCategoryStore: TrackerCategoryStoring
    private let trackerRecordStore: TrackerRecordStoring
    private var currentDate: Date = Date()
    
    private var visibleCategories: [TrackerCategory] {
        let weekday = Weekday.from(date: currentDate)
        let isFutureDate = currentDate > Date()
        
        let persistentCategories: [PersistentCategory]
        do {
            persistentCategories = try trackerCategoryStore.fetchCategories()
        } catch {
            print("Ошибка получения категорий: \(error)")
            return []
        }
        
        return persistentCategories.compactMap { persistentCategory -> TrackerCategory? in
            let filteredTrackers = persistentCategory.trackers.filter { tracker in
                if isFutureDate { return false }
                return tracker.schedule.contains(weekday.rawValue)
            }
            
            let trackerObjects: [Tracker] = filteredTrackers.compactMap { persistentTracker in
                let color = UIColor(named: persistentTracker.colorName) ?? .systemGray
                let weekdays = persistentTracker.schedule.compactMap { Weekday(rawValue: $0) }
                return Tracker(
                    id: persistentTracker.id,
                    name: persistentTracker.name,
                    color: color,
                    emoji: persistentTracker.emoji,
                    schedule: weekdays
                )
            }
            
            return trackerObjects.isEmpty ? nil : TrackerCategory(
                title: persistentCategory.title,
                trackers: trackerObjects
            )
        }
    }
    
    // MARK: - UI
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = UIFont.boldSystemFont(ofSize: 34)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Поиск"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    private let starImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "bw_star"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        dp.translatesAutoresizingMaskIntoConstraints = false
        dp.maximumDate = Date()
        return dp
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 16
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        cv.register(SectionHeader.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: "header")
        return cv
    }()
    
    // MARK: - Инициализатор (теперь только протоколы)
    init(
        trackerStore: TrackerStoring,
        trackerCategoryStore: TrackerCategoryStoring,
        trackerRecordStore: TrackerRecordStoring
    ) {
        self.trackerStore = trackerStore
        self.trackerCategoryStore = trackerCategoryStore
        self.trackerRecordStore = trackerRecordStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        searchBar.delegate = self
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        view.addSubview(plusButton)
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(datePicker)
        view.addSubview(starImageView)
        view.addSubview(descriptionLabel)
        view.addSubview(collectionView)
        
        setupConstraints()
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        updatePlaceholderVisibility()
    }
    
    // MARK: - Действия
    @objc private func plusButtonTapped() {
        let habitVC = HabitViewController()
        habitVC.onSave = { [weak self] persistentTracker in
            guard let self else { return }
            do {
                try self.trackerStore.addNewTracker(persistentTracker)
                print("Добавлен трекер: \(persistentTracker.name)")
                self.collectionView.reloadData()
                self.updatePlaceholderVisibility()
            } catch {
                print("Ошибка добавления трекера: \(error)")
            }
        }
        
        let nav = UINavigationController(rootViewController: habitVC)
        present(nav, animated: true)
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        collectionView.reloadData()
        updatePlaceholderVisibility()
    }
    
    private func updatePlaceholderVisibility() {
        let isEmpty = visibleCategories.isEmpty
        starImageView.isHidden = !isEmpty
        descriptionLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
    
    private func handleTrackerCompletion(trackerId: UUID, shouldComplete: Bool, indexPath: IndexPath) {
        let record = PersistentRecord(id: UUID(), date: currentDate, trackerId: trackerId)
        
        do {
            if shouldComplete {
                if currentDate > Date() { return }
                try trackerRecordStore.addRecord(record)
            } else {
                try trackerRecordStore.deleteRecord(id: record.id)
            }
            collectionView.reloadItems(at: [indexPath])
        } catch {
            print("Ошибка при обновлении записи: \(error)")
        }
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            plusButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            plusButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 6),
            plusButton.widthAnchor.constraint(equalToConstant: 42),
            plusButton.heightAnchor.constraint(equalToConstant: 42),
            
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            datePicker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            datePicker.widthAnchor.constraint(equalToConstant: 100),
            
            titleLabel.topAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 1),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            starImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 80),
            starImageView.heightAnchor.constraint(equalToConstant: 80),
            
            descriptionLabel.topAnchor.constraint(equalTo: starImageView.bottomAnchor, constant: 7),
            descriptionLabel.centerXAnchor.constraint(equalTo: starImageView.centerXAnchor)
        ])
    }
}

// MARK: - CollectionView
extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.identifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        let viewModel = makeTrackerViewModel(for: tracker)
        
        cell.configure(
            with: viewModel.tracker,
            isCompletedToday: viewModel.isCompletedToday,
            completionCount: viewModel.completionCount,
            completionHandler: { [weak self] trackerId, shouldComplete in
                self?.handleTrackerCompletion(
                    trackerId: trackerId,
                    shouldComplete: shouldComplete,
                    indexPath: indexPath
                )
            }
        )
        
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "header",
            for: indexPath
        ) as? SectionHeader else {
            assertionFailure("Error")
            return UICollectionReusableView()
        }
        
        header.titleLabel.text = visibleCategories[indexPath.section].title
        return header
    }
    
    private func makeTrackerViewModel(for tracker: Tracker) -> (tracker: Tracker, isCompletedToday: Bool, completionCount: Int) {
        let records: [PersistentRecord]
        do {
            records = try trackerRecordStore.fetchRecords()
        } catch {
            print("Ошибка загрузки записей: \(error)")
            return (tracker, false, 0)
        }
        
        let completionCount = records.filter { $0.trackerId == tracker.id }.count
        let isCompletedToday = records.contains {
            $0.trackerId == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: currentDate)
        }
        return (tracker, isCompletedToday, completionCount)
    }
}

extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width
        let itemWidth = (availableWidth - 8) / 2
        return CGSize(width: itemWidth, height: 148)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 40)
    }
}

// MARK: - Section Header
final class SectionHeader: UICollectionReusableView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.textColor = UIColor(named: "ypBlackDay") ?? .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
