import UIKit
import Foundation

// MARK: - ViewModel
final class CategoryListViewModel {
    private let categoryStore: TrackerCategoryStoring
    private var categories: [PersistentCategory] = []
    private(set) var selectedCategoryTitle: String?
    
    var onCategoriesUpdated: (() -> Void)?
    var onPlaceholderVisibilityChanged: ((Bool) -> Void)?
    
    var categoryStoreAccessor: TrackerCategoryStoring {
        categoryStore
    }
    
    init(categoryStore: TrackerCategoryStoring, selectedCategoryTitle: String? = nil) {
        self.categoryStore = categoryStore
        self.selectedCategoryTitle = selectedCategoryTitle
        fetchCategories()
    }
    
    func fetchCategories() {
        do {
            categories = try categoryStore.fetchCategories()
            print("Загружено категорий: \(categories.count), названия: \(categories.map { $0.title })")
            onCategoriesUpdated?()
            onPlaceholderVisibilityChanged?(categories.isEmpty)
        } catch {
            print("Ошибка получения категорий: \(error)")
            categories = []
            onCategoriesUpdated?()
            onPlaceholderVisibilityChanged?(true)
        }
    }
    
    func numberOfCategories() -> Int {
        return categories.count
    }
    
    func category(at index: Int) -> PersistentCategory {
        return categories[index]
    }
    
    func selectCategory(at index: Int) {
        selectedCategoryTitle = categories[index].title
        onCategoriesUpdated?()
    }
}

// MARK: - ViewController
final class CategoryListViewController: UIViewController, TrackerCategoryStoreDelegate {
    var onSelect: ((String) -> Void)?
    
    private let viewModel: CategoryListViewModel
    
    // Сохраняем constraint для высоты, чтобы обновлять его
    private var cardViewHeightConstraint: NSLayoutConstraint?
    
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
    
    private let starImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "bw_star"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .center
        let attributedText = NSAttributedString(
            string: Localization.emptyCategoriesMessage,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .paragraphStyle: paragraphStyle
            ]
        )
        label.attributedText = attributedText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Localization.addCategoryButton, for: .normal)
        button.backgroundColor = .ypBlackDay
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(categoryStore: TrackerCategoryStoring, selectedCategoryTitle: String? = nil) {
        self.viewModel = CategoryListViewModel(categoryStore: categoryStore, selectedCategoryTitle: selectedCategoryTitle)
        super.init(nibName: nil, bundle: nil)
        if let store = categoryStore as? TrackerCategoryStore {
            store.delegate = self
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        viewModel.onPlaceholderVisibilityChanged?(viewModel.numberOfCategories() == 0)
    }
    
    // Обновляем данные каждый раз при появлении экрана
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchCategories()
    }
    
    private func setupUI() {
        title = Localization.categoryTitle
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        
        view.addSubview(cardView)
        cardView.addSubview(tableView)
        view.addSubview(starImageView)
        view.addSubview(descriptionLabel)
        view.addSubview(addCategoryButton)
        
        // Создаем constraint для высоты один раз и сохраняем его
        let heightConstraint = cardView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        cardViewHeightConstraint = heightConstraint
        
        updateTableHeight()
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: cardView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            starImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            starImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            starImageView.widthAnchor.constraint(equalToConstant: 80),
            starImageView.heightAnchor.constraint(equalToConstant: 80),
            
            descriptionLabel.topAnchor.constraint(equalTo: starImageView.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupBindings() {
        viewModel.onCategoriesUpdated = { [weak self] in
            print("Обновление таблицы категорий")
            self?.tableView.reloadData()
            self?.updateTableHeight()
        }
        viewModel.onPlaceholderVisibilityChanged = { [weak self] isEmpty in
            print("Плейсхолдер: isEmpty = \(isEmpty), категории: \(self?.viewModel.numberOfCategories() ?? 0)")
            self?.starImageView.isHidden = !isEmpty
            self?.descriptionLabel.isHidden = !isEmpty
            self?.cardView.isHidden = isEmpty
        }
    }
    
    private func updateTableHeight() {
        let tableHeight = CGFloat(viewModel.numberOfCategories()) * 75
        // Обновляем существующий constraint вместо создания нового
        cardViewHeightConstraint?.constant = tableHeight
    }
    
    @objc private func addCategoryTapped() {
        let editViewController = CategoryEditViewController(categoryStore: viewModel.categoryStoreAccessor)
        editViewController.onCategoryAdded = { [weak self] in
            print("Категория добавлена, обновляем список")
            self?.viewModel.fetchCategories()
        }
        navigationController?.pushViewController(editViewController, animated: true)
    }
    
    // MARK: - TrackerCategoryStoreDelegate
    func store(_ store: TrackerCategoryStore, didUpdate update: TrackerCategoryStoreUpdate) {
        print("Получено обновление от store")
        viewModel.fetchCategories()
    }
}

extension CategoryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCategories()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseId,
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let category = viewModel.category(at: indexPath.row)
        let isSelected = category.title == viewModel.selectedCategoryTitle
        cell.configure(title: category.title, isSelected: isSelected)
        
        return cell
    }
}

extension CategoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 75 }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectCategory(at: indexPath.row)
        if let selectedCategoryTitle = viewModel.selectedCategoryTitle {
            onSelect?(selectedCategoryTitle)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastRow = tableView.numberOfRows(inSection: indexPath.section) - 1
        if indexPath.row == lastRow {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let category = viewModel.category(at: indexPath.row)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: [
                UIAction(title: Localization.editAction) { [weak self] _ in
                    guard let self = self else { return }
                    let renameVC = CategoryRenameViewController(categoryStore: self.viewModel.categoryStoreAccessor, categoryTitle: category.title)
                    renameVC.onCategoryRenamed = { [weak self] in
                        self?.viewModel.fetchCategories()
                    }
                    self.navigationController?.pushViewController(renameVC, animated: true)
                },
                UIAction(title: Localization.deleteAction, attributes: .destructive) { [weak self] _ in
                    self?.showDeleteConfirmation(for: category.title)
                }
            ])
        }
    }
    
    private func showDeleteConfirmation(for categoryTitle: String) {
        let alert = UIAlertController(
            title: Localization.deleteCategoryConfirmation,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: Localization.deleteButton, style: .destructive) { [weak self] _ in
            do {
                try self?.viewModel.categoryStoreAccessor.deleteCategory(title: categoryTitle)
            } catch {
                print("Ошибка удаления категории: \(error)")
                let errorAlert = UIAlertController(
                    title: NSLocalizedString("error_title", comment: "Error title"),
                    message: NSLocalizedString("error_delete_category", comment: "Error deleting category"),
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: Localization.cancelAction, style: .default))
                self?.present(errorAlert, animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: Localization.cancelAction, style: .cancel))
        present(alert, animated: true)
    }
}

final class CategoryCell: UITableViewCell {
    static let reuseId = "CategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = .ypBlackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .default
        
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40)
        ])
    }
    
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        accessoryType = isSelected ? .checkmark : .none
    }
}
