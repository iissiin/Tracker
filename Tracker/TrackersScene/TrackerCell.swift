import UIKit

final class TrackerCell: UICollectionViewCell {
    static let identifier = "TrackerCell"
    
    // MARK: - UI
    
    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let counterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlackDay
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 17
        button.backgroundColor = cardView.backgroundColor
        button.tintColor = .white
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    
    // MARK: - Properties
    private var trackerId: UUID?
    private var isCompletedToday = false
    private var completionHandler: ((UUID, Bool) -> Void)?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(emojiBackground)
        emojiBackground.addSubview(emojiLabel)
        cardView.addSubview(nameLabel)
        
        contentView.addSubview(bottomView)
        bottomView.addSubview(counterLabel)
        bottomView.addSubview(plusButton)
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            
            emojiBackground.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiBackground.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            emojiBackground.widthAnchor.constraint(equalToConstant: 24),
            emojiBackground.heightAnchor.constraint(equalToConstant: 24),
            
            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackground.centerYAnchor),
            
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            nameLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            
            bottomView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 16),
            bottomView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 34),
            bottomView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            counterLabel.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 12),
            counterLabel.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
            
            plusButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -12),
            plusButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 34),
            plusButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    // MARK: - Config
    func configure(
        with tracker: Tracker,
        isCompletedToday: Bool = false,
        completionCount: Int = 0,
        completionHandler: ((UUID, Bool) -> Void)? = nil
    ) {
        self.trackerId = tracker.id
        self.isCompletedToday = isCompletedToday
        self.completionHandler = completionHandler
        
        nameLabel.text = tracker.name
        cardView.backgroundColor = tracker.color
        emojiLabel.text = tracker.emoji
        counterLabel.text = "\(completionCount) дней"
        
        updateButtonAppearance()
    }
    
    private func updateButtonAppearance() {
        if isCompletedToday {
            plusButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
            plusButton.tintColor = .white
            plusButton.backgroundColor = cardView.backgroundColor?.withAlphaComponent(0.5) 
        } else {
            plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
            plusButton.tintColor = .white
            plusButton.backgroundColor = cardView.backgroundColor
        }
    }

    @objc private func plusButtonTapped() {
        guard let trackerId = trackerId else { return }
        isCompletedToday.toggle()
        updateButtonAppearance()
        completionHandler?(trackerId, isCompletedToday)
    }
}
