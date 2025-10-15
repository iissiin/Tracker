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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRecordChange),
            name: .trackerRecordChanged,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем статистику при каждом появлении экрана
        loadStats()
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
        let calculator = StatisticsCalculator(
            trackerRecordStore: trackerRecordStore,
            trackerStore: trackerStore
        )
        stats = calculator.calculate()
        print("Статистика обновлена: \(stats?.completedTrackers ?? 0) завершенных трекеров")
    }

    private func updateUI() {
        tableView.reloadData()
        updatePlaceholder()
    }

    private func updatePlaceholder() {
        guard let stats = stats else {
            tableView.isHidden = true
            noStatsImageView.isHidden = false
            noStatsLabel.isHidden = false
            return
        }
        
        let isEmpty = stats.bestPeriod == 0 &&
                      stats.idealDays == 0 &&
                      stats.completedTrackers == 0 &&
                      stats.averagePerDay == 0
        
        tableView.isHidden = isEmpty
        noStatsImageView.isHidden = !isEmpty
        noStatsLabel.isHidden = !isEmpty
    }

    @objc private func handleRecordChange(_ notification: Notification) {
        print("Получено уведомление об изменении записи, обновляем статистику")
        loadStats()
    }
}

extension StatisticsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "StatsCell",
            for: indexPath
        ) as? StatisticsCell else {
            return UITableViewCell()
        }
        
        guard let stats = stats else { return cell }
        
        switch indexPath.section {
        case 0:
            cell.configure(number: stats.bestPeriod, description: Localization.bestPeriod)
        case 1:
            cell.configure(number: stats.idealDays, description: Localization.perfectDays)
        case 2:
            cell.configure(number: stats.completedTrackers, description: Localization.completedTrackers)
        case 3:
            cell.configure(number: stats.averagePerDay, description: Localization.averageValue)
        default:
            break
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section < 3 ? 16 : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}
