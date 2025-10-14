import UIKit

final class StatisticsViewController: UIViewController {
    private let trackerRecordStore: TrackerRecordStoring
    private let trackerStore: TrackerStoring

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = Localization.statisticsTitle
        label.font = UIFont.boldSystemFont(ofSize: 34)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.register(StatisticsCell.self, forCellReuseIdentifier: "StatsCell")
        return tv
    }()

    private let noStatsImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "bw_cryEmoji"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let noStatsLabel: UILabel = {
        let label = UILabel()
        label.text = Localization.noStatsMessage
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var stats: StatisticsCalculator.Stats? {
        didSet {
            updateUI()
        }
    }

    init(trackerRecordStore: TrackerRecordStoring, trackerStore: TrackerStoring) {
        self.trackerRecordStore = trackerRecordStore
        self.trackerStore = trackerStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self
        setupUI()
        loadStats()
        NotificationCenter.default.addObserver(self, selector: #selector(handleRecordChange), name: .trackerRecordChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(noStatsImageView)
        view.addSubview(noStatsLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 77),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -126),

            noStatsImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noStatsImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            noStatsImageView.widthAnchor.constraint(equalToConstant: 80),
            noStatsImageView.heightAnchor.constraint(equalToConstant: 80),

            noStatsLabel.topAnchor.constraint(equalTo: noStatsImageView.bottomAnchor, constant: 8),
            noStatsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        updatePlaceholder()
    }

    private func loadStats() {
        let calculator = StatisticsCalculator(trackerRecordStore: trackerRecordStore, trackerStore: trackerStore)
        stats = calculator.calculate()
    }

    private func updateUI() {
        tableView.reloadData()
        updatePlaceholder()
    }

    private func updatePlaceholder() {
        guard let stats = stats else { return }
        let isEmpty = stats.bestPeriod == 0 && stats.idealDays == 0 && stats.completedTrackers == 0 && stats.averagePerDay == 0
        tableView.isHidden = isEmpty
        noStatsImageView.isHidden = !isEmpty
        noStatsLabel.isHidden = !isEmpty
    }

    @objc private func handleRecordChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let trackerId = userInfo["trackerId"] as? UUID,
              let isCompleted = userInfo["isCompleted"] as? Bool,
              let date = userInfo["date"] as? Date else {
            loadStats() // Если данных нет, делаем полный пересчёт
            return
        }

        // Пытаемся обновить статистику инкрементально
        var newStats = stats ?? StatisticsCalculator.Stats(bestPeriod: 0, idealDays: 0, completedTrackers: 0, averagePerDay: 0)
        let calendar = Calendar.current
        let currentDay = calendar.startOfDay(for: date)

        do {
            let records = try trackerRecordStore.fetchAllRecords()
            let totalTrackers = try trackerStore.fetchAllTrackersCount()
            let recordsForDay = records.filter { calendar.isDate($0.date, inSameDayAs: currentDay) }

            if isCompleted {
                newStats.completedTrackers += 1
            } else {
                newStats.completedTrackers -= 1
            }

            if recordsForDay.count == totalTrackers && !isCompleted {
                newStats.idealDays -= 1
            } else if (recordsForDay.count + (isCompleted ? 1 : 0)) == totalTrackers {
                newStats.idealDays += 1
            }

            let uniqueDays = Set(records.map { calendar.startOfDay(for: $0.date) }).count
            newStats.averagePerDay = uniqueDays > 0 ? newStats.completedTrackers / uniqueDays : 0

            let calculator = StatisticsCalculator(trackerRecordStore: trackerRecordStore, trackerStore: trackerStore)
            let fullStats = calculator.calculate()
            newStats.bestPeriod = fullStats.bestPeriod

            stats = newStats
        } catch {
            print("Ошибка при обновлении статистики: \(error)")
            loadStats()
        }
    }
}

extension StatisticsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 4 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath) as! StatisticsCell
        guard let stats = stats else { return cell }
        switch indexPath.section {
        case 0: cell.configure(number: stats.bestPeriod, description: Localization.bestPeriod)
        case 1: cell.configure(number: stats.idealDays, description: Localization.perfectDays)
        case 2: cell.configure(number: stats.completedTrackers, description: Localization.completedTrackers)
        case 3: cell.configure(number: stats.averagePerDay, description: Localization.averageValue)
        default: break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 90 }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 16 }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}
