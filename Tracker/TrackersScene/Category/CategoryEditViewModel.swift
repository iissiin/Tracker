import UIKit

// MARK: - ViewModel
final class CategoryEditViewModel {
    private let categoryStore: TrackerCategoryStoring
    var onCategoryAdded: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    init(categoryStore: TrackerCategoryStoring) {
        self.categoryStore = categoryStore
    }
    
    func addCategory(title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onError?(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Название категории не может быть пустым"]))
            return
        }
        
        do {
            try categoryStore.addNewCategory(title: title)
            onCategoryAdded?()
        } catch TrackerCategoryStoreError.duplicateTitle {
            onError?(TrackerCategoryStoreError.duplicateTitle)
        } catch {
            onError?(error)
        }
    }
}

// MARK: - ViewController
final class CategoryEditViewController: UIViewController {
    private let viewModel: CategoryEditViewModel
    
    var onCategoryAdded: (() -> Void)?
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название категории"
        textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textField.backgroundColor = UIColor(named: "YP_Background[day]") ?? .systemGray6
        textField.layer.cornerRadius = 16
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.backgroundColor = .ypBlackDay
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(categoryStore: TrackerCategoryStoring) {
        self.viewModel = CategoryEditViewModel(categoryStore: categoryStore)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        title = "Новая категория"
        view.backgroundColor = .systemBackground
        
        navigationItem.hidesBackButton = true
        
        view.addSubview(titleTextField)
        view.addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 75),
            
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupBindings() {
        viewModel.onCategoryAdded = { [weak self] in
            self?.onCategoryAdded?()
            self?.navigationController?.popViewController(animated: true)
        }
        
        viewModel.onError = { [weak self] error in
            let message: String
            if error is TrackerCategoryStoreError, error.localizedDescription.contains("duplicateTitle") {
                message = "Категория с таким названием уже существует"
            } else {
                message = error.localizedDescription
            }
            
            let alert = UIAlertController(
                title: "Ошибка",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    @objc private func doneButtonTapped() {
        guard let title = titleTextField.text else { return }
        viewModel.addCategory(title: title)
    }
}
