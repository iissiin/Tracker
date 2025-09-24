import UIKit

final class HabitViewController: UIViewController {
    
    // MARK: - Public callback
    var onSave: ((Tracker) -> Void)?
    
    // MARK: - State
    private var selectedDays: [Weekday] = []
    private var selectedEmoji: String?
    private var selectedColorName: String?
    
    private let emojis: [String] = ["🙂","😻","🌺","🐶","❤️","😱","😇","😡","🥶","🤔","🙌","🍔","🥦","🏓","🥇","🎸","🏖️","😪"]
    private let colors: [String] = (1...18).map { "selection_\($0)" }
    
    private var emojiCollectionViewHeight: NSLayoutConstraint?
    private var colorCollectionViewHeight: NSLayoutConstraint?
    
    // MARK: - UI
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Введите название трекера"
        tf.backgroundColor = UIColor.systemGray6
        tf.layer.cornerRadius = 16
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        tf.leftViewMode = .always
        tf.clearButtonMode = .whileEditing
        tf.returnKeyType = .done
        tf.delegate = self
        tf.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        return tf
    }()
    
    private lazy var optionsTableView: UITableView = {
        let tv = UITableView()
        tv.layer.cornerRadius = 16
        tv.isScrollEnabled = false
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.separatorColor = UIColor(white: 0.0, alpha: 0.12)
        tv.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.reuseId)
        tv.dataSource = self
        tv.delegate = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private lazy var emojiLabel: UILabel = {
        let l = UILabel()
        l.text = "Emoji"
        l.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var emojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseId)
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.allowsMultipleSelection = false
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.isScrollEnabled = false
        return cv
    }()
    
    private lazy var colorLabel: UILabel = {
        let l = UILabel()
        l.text = "Цвет"
        l.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseId)
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.allowsMultipleSelection = false
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.isScrollEnabled = false
        return cv
    }()
    
    private lazy var buttonsStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 12
        s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private lazy var cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Отменить", for: .normal)
        b.setTitleColor(.systemRed, for: .normal)
        b.backgroundColor = .systemBackground
        b.layer.cornerRadius = 16
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemRed.cgColor
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        b.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    private lazy var createButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Создать", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .systemGray
        b.layer.cornerRadius = 16
        b.isEnabled = false
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        b.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        emojiCollectionView.reloadData()
        colorCollectionView.reloadData()
        updateCreateButtonState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let layout = emojiCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.invalidateLayout()
            emojiCollectionView.layoutIfNeeded()
            emojiCollectionViewHeight?.constant = layout.collectionViewContentSize.height
        }

        if let layout = colorCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.invalidateLayout()
            colorCollectionView.layoutIfNeeded()
            colorCollectionViewHeight?.constant = layout.collectionViewContentSize.height
        }
    }
    
    // MARK: - Setup UI / Layout
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        view.addSubview(buttonsStackView)
        scrollView.addSubview(contentView)
        
        [titleTextField, optionsTableView, emojiLabel, emojiCollectionView, colorLabel, colorCollectionView]
            .forEach { contentView.addSubview($0) }
        
        buttonsStackView.addArrangedSubview(cancelButton)
        buttonsStackView.addArrangedSubview(createButton)
        
        optionsTableView.tableFooterView = UIView()
        
        emojiCollectionViewHeight = emojiCollectionView.heightAnchor.constraint(equalToConstant: 0)
        emojiCollectionViewHeight?.isActive = true

        colorCollectionViewHeight = colorCollectionView.heightAnchor.constraint(equalToConstant: 0)
        colorCollectionViewHeight?.isActive = true

        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonsStackView.topAnchor, constant: -16),
            
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 60),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 75),
            
            optionsTableView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 24),
            optionsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsTableView.heightAnchor.constraint(equalToConstant: 150),
            
            emojiLabel.topAnchor.constraint(equalTo: optionsTableView.bottomAnchor, constant: 24),
            emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            emojiCollectionView.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 12),
            emojiCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            colorLabel.topAnchor.constraint(equalTo: emojiCollectionView.bottomAnchor, constant: 32),
            colorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            
            colorCollectionView.topAnchor.constraint(equalTo: colorLabel.bottomAnchor, constant: 12),
            colorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            colorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            colorCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Новая привычка"
    }
    
    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createButtonTapped() {
        guard let title = titleTextField.text, !title.isEmpty,
              let emoji = selectedEmoji,
              let colorName = selectedColorName else { return }
        
        let color = UIColor(named: colorName) ?? .systemGreen
        let newTracker = Tracker(id: UUID(), name: title, color: color, emoji: emoji, schedule: selectedDays)
        onSave?(newTracker)
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, text.count > 38 {
            textField.text = String(text.prefix(38))
        }
        updateCreateButtonState()
    }
    
    private func updateCreateButtonState() {
        let isTitleValid = !(titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let isScheduleSelected = !selectedDays.isEmpty
        let isEmojiSelected = selectedEmoji != nil
        let isColorSelected = selectedColorName != nil
        createButton.isEnabled = isTitleValid && isScheduleSelected && isEmojiSelected && isColorSelected
        createButton.backgroundColor = createButton.isEnabled ? .black : .systemGray
    }
}

// MARK: - UITableViewDataSource & Delegate
extension HabitViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 75 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.reuseId, for: indexPath) as? OptionTableViewCell else {
            return UITableViewCell()
        }
        if indexPath.row == 0 {
            cell.configure(title: "Категория", value: nil)
        } else {
            let daysText: String?
            if selectedDays.count == Weekday.allCases.count {
                daysText = "Каждый день"
            } else {
                daysText = selectedDays.isEmpty ? nil : selectedDays.map { $0.shortSymbol }.joined(separator: ", ")
            }
            cell.configure(title: "Расписание", value: daysText)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 {
            let scheduleVC = ScheduleViewController()
            scheduleVC.selectedDays = selectedDays
            scheduleVC.onFinish = { [weak self] days in
                self?.selectedDays = days
                tableView.reloadData()
                self?.updateCreateButtonState()
            }
            navigationController?.pushViewController(scheduleVC, animated: true)
        }
    }
}

// MARK: - UICollectionView DataSource / Delegate / FlowLayout
extension HabitViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == emojiCollectionView ? emojis.count : colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCell.reuseId, for: indexPath) as! EmojiCell
            let emoji = emojis[indexPath.item]
            cell.configure(with: emoji, selected: emoji == selectedEmoji)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorCell.reuseId, for: indexPath) as! ColorCell
            let colorName = colors[indexPath.item]
            let color = UIColor(named: colorName) ?? UIColor.systemGray
            let isSelected = colorName == selectedColorName
            cell.configure(color: color, selected: isSelected)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            selectedEmoji = emojis[indexPath.item]
            collectionView.reloadData()
        } else {
            selectedColorName = colors[indexPath.item]
            collectionView.reloadData()
        }
        updateCreateButtonState()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == emojiCollectionView {
            // Фиксированный размер 52x52 для эмодзи
            return CGSize(width: 52, height: 52)
        } else {
            // Фиксированный размер 52x52 для цветов
            return CGSize(width: 52, height: 52)
        }
    }
}

// MARK: - UITextFieldDelegate
extension HabitViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        updateCreateButtonState()
    }
}

// MARK: - Cells
final class EmojiCell: UICollectionViewCell {
    static let reuseId = "EmojiCell"
    private let label: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        contentView.layer.cornerRadius = 16 // Закругление углов 16px
        contentView.layer.masksToBounds = true
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with emoji: String, selected: Bool) {
        label.text = emoji
        contentView.backgroundColor = selected ? UIColor.systemGray4 : UIColor.clear // Серый фон для выбранной ячейки, прозрачный для невыбранной
        contentView.layer.borderWidth = 0 // Убираем контур
    }
}

final class ColorCell: UICollectionViewCell {
    static let reuseId = "ColorCell"
    private let colorView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 8
        v.layer.masksToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(colorView)
        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = false
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(color: UIColor, selected: Bool) {
        colorView.backgroundColor = color
        if selected {
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        } else {
            contentView.layer.borderWidth = 0
        }
    }
}

final class OptionTableViewCell: UITableViewCell {
    static let reuseId = "OptionCell"
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textColor = .systemGray
        l.isHidden = true
        return l
    }()
    private lazy var labelsStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        s.axis = .vertical
        s.spacing = 4
        s.alignment = .leading
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(labelsStack)
        NSLayoutConstraint.activate([
            labelsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            labelsStack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40),
            labelsStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        accessoryType = .disclosureIndicator
        backgroundColor = .systemGray6
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(title: String, value: String?) {
        titleLabel.text = title
        if let value, !value.isEmpty {
            valueLabel.text = value
            valueLabel.isHidden = false
        } else {
            valueLabel.text = nil
            valueLabel.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        valueLabel.text = nil
        valueLabel.isHidden = true
    }
}
