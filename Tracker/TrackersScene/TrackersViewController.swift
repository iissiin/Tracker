import UIKit

final class TrackersViewController: UIViewController, UISearchBarDelegate {
    // MARK: - Хранение данных
    private var trackers: [Tracker] = []
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate: Date = Date()
    
    // MARK: - Модели
    struct Tracker {
        let id: UUID
        let name: String
        let color: UIColor
        let emoji: String
        let schedule: [Weekday]
    }

    struct TrackerRecord: Hashable {
        let id: UUID
        let date: Date
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
        return cv
    }()


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
        habitVC.onSave = { [weak self] tracker in
            guard let self else { return }
            self.trackers.append(tracker)
            self.collectionView.reloadData()
            self.updatePlaceholderVisibility()
            print("Добавлен трекер: \(tracker.name)")
        }
        
        let nav = UINavigationController(rootViewController: habitVC)
        present(nav, animated: true)
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        collectionView.reloadData()
    }

    private func updatePlaceholderVisibility() {
        let isEmpty = trackers.isEmpty
        starImageView.isHidden = !isEmpty
        descriptionLabel.isHidden = !isEmpty
    }
    
    private func handleTrackerCompletion(trackerId: UUID, shouldComplete: Bool, indexPath: IndexPath) {
        if shouldComplete {
            let record = TrackerRecord(id: trackerId, date: currentDate)
            completedTrackers.append(record)
        } else {
            completedTrackers.removeAll {
                $0.id == trackerId && Calendar.current.isDate($0.date, inSameDayAs: currentDate)
            }
        }
        
        collectionView.reloadItems(at: [indexPath])
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
            searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        trackers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.identifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }

        let tracker = trackers[indexPath.item]
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
    
    private func makeTrackerViewModel(for tracker: Tracker) -> (tracker: Tracker, isCompletedToday: Bool, completionCount: Int) {
        let completionCount = completedTrackers.filter { $0.id == tracker.id }.count
        let isCompletedToday = completedTrackers.contains {
            $0.id == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: Date())
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
}

