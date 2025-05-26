//
//  StatsHorizontalStackView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 30/8/2024.
//

import UIKit

class StatsHorizontalStackView: UIStackView {

    private var separatorViews: [UIView] = []
    
    init() {
        super.init(frame: .zero)
        self.axis = .horizontal
        self.distribution = .fillProportionally
        self.alignment = .center
        self.spacing = 20
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.axis = .horizontal
        self.distribution = .fillProportionally
        self.alignment = .center
        self.spacing = 20
    }
    
    func configure(with data: [(numberText: String, descriptionText: String)]) {
        for (index, item) in data.enumerated() {
            let stackView = createVerticalStackView(with: item.numberText, descriptionText: item.descriptionText)
            self.addArrangedSubview(stackView)
            
            if index < data.count - 1 {
                let separator = createSeparatorView()
                separatorViews.append(separator)
                self.addArrangedSubview(separator)
            }
        }
    }

    private func createVerticalStackView(with numberText: String, descriptionText: String) -> UIStackView {
        let numberLabel = createStatsNumberLabel(withText: numberText)
        let descriptionLabel = createStatsTextLabel(withText: descriptionText)
        
        let stackView = UIStackView(arrangedSubviews: [numberLabel, descriptionLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = -7
        return stackView
    }
    
    private func createStatsNumberLabel(withText text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont(name: "Avenir", size: 32)
        label.textAlignment = .center
        label.textColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
        return label
    }
    
    private func createStatsTextLabel(withText text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont(name: "Avenir", size: 16)
        label.textAlignment = .center
        label.textColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.numberOfLines = 1
        return label
    }
    
    private func createSeparatorView() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        NSLayoutConstraint.activate([
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.heightAnchor.constraint(equalToConstant: 50)
        ])
        return separator
    }

    func updateStats(at index: Int, withNumberText text: String) {
        guard let stackView = arrangedSubviews[safe: index * 2] as? UIStackView,
              let numberLabel = stackView.arrangedSubviews.first as? UILabel else { return }
        numberLabel.text = text
    }
    
    func updateLabelColors(_ color: UIColor) {
        for arrangedSubview in arrangedSubviews {
            if let stackView = arrangedSubview as? UIStackView {
                for label in stackView.arrangedSubviews {
                    if let label = label as? UILabel {
                        label.textColor = color
                    }
                }
            } else if let separator = arrangedSubview as? UIView {
                separator.backgroundColor = color
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let color = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        updateLabelColors(color)
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
