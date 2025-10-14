import Foundation
import UIKit

enum FilterType: String {
    case all = "all_trackers"
    case today = "today_trackers"
    case completed = "completed_trackers_filter"
    case incomplete = "incomplete_trackers"
    
    var localizedTitle: String {
        return NSLocalizedString(self.rawValue, comment: "Filter type title")
    }
}

final class FiltersViewController: UIViewController {
    
    private let currentFilter: FilterType?
    var onSelect: ((FilterType) -> Void)?
    
    private let filters: [FilterType] = [.all, .today, .completed, .incomplete]
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(named: "YP_Background[day]") ?? .systemGray6
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseId)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.separatorColor = UIColor(named: "ypGray")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    init(currentFilter: FilterType?) {
        self.currentFilter = currentFilter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = Localization.filtersTitle
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        
        view.addSubview(cardView)
        cardView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cardView.heightAnchor.constraint(equalToConstant: 300),
            
            tableView.topAnchor.constraint(equalTo: cardView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])
    }
    
    @objc private func dismissView() {
        dismiss(animated: true)
    }
}

extension FiltersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseId,
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let filter = filters[indexPath.row]
        let isSelected = filter == currentFilter && (filter == .completed || filter == .incomplete)
        cell.configure(title: filter.localizedTitle, isSelected: isSelected)
        
        return cell
    }
}

extension FiltersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 75 }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let filter = filters[indexPath.row]
        onSelect?(filter)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastRow = tableView.numberOfRows(inSection: indexPath.section) - 1
        if indexPath.row == lastRow {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
}
