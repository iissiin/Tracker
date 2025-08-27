import UIKit

final class ScheduleViewController: UIViewController {

    // MARK: - Public API
    var selectedDays: [Weekday] = []
    var onFinish: (([Weekday]) -> Void)?

    // MARK: - UI
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(named: "YP_Background[day]") ?? .systemGray6
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.register(ScheduleCell.self, forCellReuseIdentifier: ScheduleCell.reuseId)
        tv.isScrollEnabled = false
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.separatorColor = UIColor(white: 0.0, alpha: 0.2)
        tv.dataSource = self
        tv.delegate = self
        tv.backgroundColor = .clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var doneButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Готово", for: .normal)
        btn.backgroundColor = .ypBlackDay
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        btn.layer.cornerRadius = 16
        btn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        navigationItem.hidesBackButton = true
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Расписание"
        view.backgroundColor = .systemBackground

        view.addSubview(cardView)
        cardView.addSubview(tableView)
        view.addSubview(doneButton)

        let tableHeight = CGFloat(Weekday.allCases.count) * 75

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.heightAnchor.constraint(equalToConstant: tableHeight),

            tableView.topAnchor.constraint(equalTo: cardView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Actions
    @objc private func doneTapped() {
        onFinish?(selectedDays)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Weekday.allCases.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ScheduleCell.reuseId,
            for: indexPath
        ) as? ScheduleCell else {
            return UITableViewCell()
        }

        let weekday = Weekday.allCases[indexPath.row]

        cell.configure(title: weekday.fullName, isOn: selectedDays.contains(weekday))

        cell.onToggle = { [weak self] isOn in
            guard let self else { return }
            if isOn {
                if !self.selectedDays.contains(weekday) { self.selectedDays.append(weekday) }
            } else {
                self.selectedDays.removeAll { $0 == weekday }
            }
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 75 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        let lastRow = tableView.numberOfRows(inSection: indexPath.section) - 1
        if indexPath.row == lastRow {
            cell.separatorInset = UIEdgeInsets(top: 0,
                                               left: tableView.bounds.width,
                                               bottom: 0,
                                               right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
}

// MARK: - Custom Cell
final class ScheduleCell: UITableViewCell {
    static let reuseId = "ScheduleCell"

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        lbl.textColor = .ypBlackDay
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let toggle: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = .ypBlue
        sw.translatesAutoresizingMaskIntoConstraints = false
        return sw
    }()

    var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(toggle)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            toggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        toggle.addTarget(self, action: #selector(didChange(_:)), for: .valueChanged)
    }

    func configure(title: String, isOn: Bool) {
        titleLabel.text = title
        toggle.isOn = isOn
    }

    @objc private func didChange(_ sender: UISwitch) {
        onToggle?(sender.isOn)
    }
}
