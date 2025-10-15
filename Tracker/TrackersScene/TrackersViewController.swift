import UIKit

final class TrackersViewController: UIViewController, UISearchBarDelegate {
    
    // MARK: - Зависимости
    private let trackerStore: TrackerStoring
    private let trackerCategoryStore: TrackerCategoryStoring
    private let trackerRecordStore: TrackerRecordStoring
    private let analyticsService = AnalyticsService()
    
    // MARK: - Хранение данных
    private var currentDate: Date = Date()
    private var persistentTrackers: [PersistentTracker] = []
    private var searchText: String = ""
    private var currentFilter: FilterType?
    
    private var hasTrackersForCurrentDay: Bool {
        let weekday = Weekday.from(date: currentDate)
        if currentDate > Date() { return false }
        let persistentCategories: [PersistentCategory]
        do {
            persistentCategories = try trackerCategoryStore.fetchCategories()
        } catch {
            print("Ошибка получения категорий: \(error)")
            return false
        }
        return persistentCategories.contains { category in
            category.trackers.contains { $0.schedule.contains(weekday.rawValue) }
        }
    }
    
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
        
        persistentTrackers.removeAll()
        
        let searchLower = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isSearching = !searchLower.isEmpty
        
        return persistentCategories.compactMap { persistentCategory -> TrackerCategory? in
            var filteredTrackers = persistentCategory.trackers.filter { tracker in
                if isFutureDate { return false }
                return tracker.schedule.contains(weekday.rawValue)
            }
            
            if isSearching {
                filteredTrackers = filteredTrackers.filter { $0.name.lowercased().contains(searchLower) }
            }
            
            if let filter = currentFilter {
                switch filter {
                case .completed:
                    filteredTrackers = filteredTrackers.filter { self.makeTrackerViewModel(for: Tracker(id: $0.id, name: $0.name, color: UIColor(named: $0.colorName) ?? .systemGray, emoji: $0.emoji, schedule: $0.schedule.compactMap { Weekday(rawValue: $0) })).isCompletedToday }
                case .incomplete:
                    filteredTrackers = filteredTrackers.filter { !self.makeTrackerViewModel(for: Tracker(id: $0.id, name: $0.name, color: UIColor(named: $0.colorName) ?? .systemGray, emoji: $0.emoji, schedule: $0.schedule.compactMap { Weekday(rawValue: $0) })).isCompletedToday }
                default:
                    break
                }
            }
            
            persistentTrackers.append(contentsOf: filteredTrackers)
            
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
    
    // MARK: - UI элементы
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = Localization.trackersTitle
        label.font = UIFont.boldSystemFont(ofSize: 34)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = Localization.searchPlaceholder
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
        label.text = Localization.emptyStateMessage
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let noSearchImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "bw_emoji"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let noSearchLabel: UILabel = {
        let label = UILabel()
        label.text = Localization.noResultsMessage
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
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
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Localization.filtersButton, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.backgroundColor = UIColor(red: 0.216, green: 0.447, blue: 0.906, alpha: 1)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filterTapped), for: .touchUpInside)
        return button
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
        cv.alwaysBounceVertical = true
        cv.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.identifier)
        cv.register(SectionHeader.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: "header")
        return cv
    }()
    
    // MARK: - Инициализатор
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
        view.backgroundColor = AppColors.background
        
        setupUIColors()
        setupSearchBar()
        setupDatePicker()
        
        searchBar.delegate = self
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        view.addSubview(plusButton)
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(datePicker)
        view.addSubview(starImageView)
        view.addSubview(descriptionLabel)
        view.addSubview(noSearchImageView)
        view.addSubview(noSearchLabel)
        view.addSubview(collectionView)
        view.addSubview(filterButton)
        
        setupConstraints()
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        updatePlaceholderVisibility()
        updateFilterButtonAppearance()
        
        analyticsService.report(event: "open", params: ["event": "open", "screen": "Main"])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        analyticsService.report(event: "close", params: ["event": "close", "screen": "Main"])
    }
    
    private func setupUIColors() {
        titleLabel.textColor = AppColors.labelPrimary
        plusButton.tintColor = AppColors.buttonPlus
        descriptionLabel.textColor = AppColors.labelSecondary
        noSearchLabel.textColor = AppColors.labelSecondary
    }
    
    private func setupSearchBar() {
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        
        if let searchTextField = searchBar.value(forKey: "searchField") as? UITextField {
            searchTextField.backgroundColor = AppColors.searchBarBackground
            searchTextField.textColor = AppColors.labelPrimary
            searchTextField.tintColor = AppColors.buttonPlus
            
            let placeholderText = Localization.searchPlaceholder
            searchTextField.attributedPlaceholder = NSAttributedString(
                string: placeholderText,
                attributes: [.foregroundColor: AppColors.labelSecondary]
            )
        }
    }
    
    private func setupDatePicker() {
        datePicker.overrideUserInterfaceStyle = .light
        datePicker.backgroundColor = AppColors.datePickerBackground
        
        datePicker.setValue(AppColors.datePickerText, forKeyPath: "textColor")
        
        datePicker.layer.cornerRadius = 8
        datePicker.layer.masksToBounds = true
    }

    
    // MARK: - Действия
    @objc private func plusButtonTapped() {
        analyticsService.report(event: "click", params: ["event": "click", "screen": "Main", "item": "add_track"])
        let habitVC = HabitViewController(trackerCategoryStore: trackerCategoryStore)
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
    
    @objc private func filterTapped() {
        analyticsService.report(event: "click", params: ["event": "click", "screen": "Main", "item": "filter"])
        let filtersVC = FiltersViewController(currentFilter: currentFilter)
        filtersVC.onSelect = { [weak self] filterType in
            guard let self else { return }
            switch filterType {
            case .all:
                self.currentFilter = nil
            case .today:
                self.currentDate = Date()
                self.datePicker.date = Date()
                self.currentFilter = nil
            case .completed:
                self.currentFilter = .completed
            case .incomplete:
                self.currentFilter = .incomplete
            }
            self.collectionView.reloadData()
            self.updatePlaceholderVisibility()
            self.updateFilterButtonAppearance()
        }
        let navController = UINavigationController(rootViewController: filtersVC)
        present(navController, animated: true)
    }
    
    private func updatePlaceholderVisibility() {
        let isEmpty = visibleCategories.isEmpty
        let isSearchingOrFiltering = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || currentFilter != nil
        
        collectionView.isHidden = isEmpty
        
        descriptionLabel.textColor = AppColors.labelSecondary
        noSearchLabel.textColor = AppColors.labelSecondary
        
        if isEmpty {
            if isSearchingOrFiltering {
                noSearchImageView.isHidden = false
                noSearchLabel.isHidden = false
                starImageView.isHidden = true
                descriptionLabel.isHidden = true
            } else {
                noSearchImageView.isHidden = true
                noSearchLabel.isHidden = true
                starImageView.isHidden = false
                descriptionLabel.isHidden = false
            }
        } else {
            noSearchImageView.isHidden = true
            noSearchLabel.isHidden = true
            starImageView.isHidden = true
            descriptionLabel.isHidden = true
        }
        
        filterButton.isHidden = !hasTrackersForCurrentDay
        let bottomInset = filterButton.isHidden ? 0 : 66.0
        collectionView.contentInset.bottom = bottomInset
        collectionView.scrollIndicatorInsets.bottom = bottomInset
    }
    
    private func updateFilterButtonAppearance() {
        if currentFilter == nil {
            filterButton.setTitleColor(.white, for: .normal)
        } else {
            filterButton.setTitleColor(.red, for: .normal)
        }
    }
    
    private func handleTrackerCompletion(trackerId: UUID, shouldComplete: Bool, indexPath: IndexPath) {
        analyticsService.report(event: "click", params: ["event": "click", "screen": "Main", "item": "track"])
        
        // Проверяем, что дата не в будущем
        if currentDate > Date() { return }
        
        do {
            // Получаем все записи для текущего трекера и даты
            let allRecords = try trackerRecordStore.fetchAllRecords()
            let existingRecord = allRecords.first { record in
                record.trackerId == trackerId && Calendar.current.isDate(record.date, inSameDayAs: currentDate)
            }
            
            if shouldComplete {
                // Если записи еще нет, создаем новую
                if existingRecord == nil {
                    let newRecord = PersistentRecord(id: UUID(), date: currentDate, trackerId: trackerId)
                    try trackerRecordStore.addRecord(newRecord)
                    print("Запись добавлена: trackerId=\(trackerId), date=\(currentDate)")
                }
            } else {
                // Если запись есть, удаляем её
                if let recordToDelete = existingRecord {
                    try trackerRecordStore.deleteRecord(id: recordToDelete.id)
                    print("Запись удалена: id=\(recordToDelete.id), trackerId=\(trackerId), date=\(currentDate)")
                }
            }
            
            // Обновляем только эту ячейку
            collectionView.reloadItems(at: [indexPath])
            
            let userInfo: [String: Any] = ["trackerId": trackerId, "isCompleted": shouldComplete, "date": currentDate]
            NotificationCenter.default.post(name: .trackerRecordChanged, object: nil, userInfo: userInfo)
        } catch {
            print("Ошибка при обновлении записи: \(error)")
        }
    }
    
    private func showDeleteConfirmation(for id: UUID, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: Localization.deleteTrackerConfirmation,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: Localization.deleteButton, style: .destructive) { [weak self] _ in
            self?.analyticsService.report(event: "click", params: ["event": "click", "screen": "Main", "item": "delete"])
            do {
                try self?.trackerStore.deleteTracker(id)
                self?.collectionView.reloadData()
                self?.updatePlaceholderVisibility()
            } catch {
                print("Ошибка удаления трекера: \(error)")
                let errorAlert = UIAlertController(
                    title: NSLocalizedString("error_title", comment: "Error title"),
                    message: NSLocalizedString("error_delete_tracker", comment: "Error deleting tracker"),
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: Localization.cancelAction, style: .default))
                self?.present(errorAlert, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: Localization.cancelAction, style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Ограничения
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
            descriptionLabel.centerXAnchor.constraint(equalTo: starImageView.centerXAnchor),
            
            noSearchImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noSearchImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            noSearchImageView.widthAnchor.constraint(equalToConstant: 80),
            noSearchImageView.heightAnchor.constraint(equalToConstant: 80),
            
            noSearchLabel.topAnchor.constraint(equalTo: noSearchImageView.bottomAnchor, constant: 8),
            noSearchLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            noSearchLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        collectionView.reloadData()
        updatePlaceholderVisibility()
    }
}

// MARK: - Коллекция
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
            assertionFailure("Ошибка")
            return UICollectionReusableView()
        }
        
        header.titleLabel.text = visibleCategories[indexPath.section].title
        return header
    }
    
    private func makeTrackerViewModel(for tracker: Tracker) -> (tracker: Tracker, isCompletedToday: Bool, completionCount: Int) {
        let records: [PersistentRecord]
        do {
            records = try trackerRecordStore.fetchAllRecords()
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
    
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        
        return UIContextMenuConfiguration(
            identifier: indexPath as NSCopying,
            previewProvider: nil
        ) { [weak self] _ in
            UIMenu(title: "", children: [
                UIAction(title: Localization.editAction) { [weak self] _ in
                    self?.analyticsService.report(event: "click", params: ["event": "click", "screen": "Main", "item": "edit"])
                    guard let self else { return }
                    
                    if let persistentTracker = self.persistentTrackers.first(where: { $0.id == tracker.id }) {
                        let habitVC = HabitViewController(
                            trackerCategoryStore: self.trackerCategoryStore,
                            editingTracker: persistentTracker
                        )
                        habitVC.onUpdate = { [weak self] updatedTracker in
                            guard let self else { return }
                            do {
                                try self.trackerStore.updateTracker(updatedTracker)
                                self.collectionView.reloadData()
                                self.updatePlaceholderVisibility()
                            } catch {
                                print("Ошибка обновления трекера: \(error)")
                            }
                        }
                        let nav = UINavigationController(rootViewController: habitVC)
                        self.present(nav, animated: true)
                    }
                },
                UIAction(title: Localization.deleteAction, attributes: .destructive) { [weak self] _ in
                    self?.showDeleteConfirmation(for: tracker.id, at: indexPath)
                }
            ])
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration
    ) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell else {
            return nil
        }
        
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.visiblePath = UIBezierPath(
            roundedRect: cell.cardView.bounds,
            cornerRadius: cell.cardView.layer.cornerRadius
        )
        
        return UITargetedPreview(view: cell.cardView, parameters: parameters)
    }
}

// MARK: - Заголовок секции
final class SectionHeader: UICollectionReusableView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.textColor = AppColors.sectionHeaderText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.background
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.textColor = AppColors.sectionHeaderText
        backgroundColor = AppColors.background
    }
}
