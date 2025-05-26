//
//  AllProfileSettingsView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 29/4/2025.
//

import UIKit

final class AllProfileSettingsView: UIView {

    private let stack = UIStackView()
    private var onEdit: ((Int) -> Void)?

    init(profile: ProfileInput, onEdit: @escaping (Int) -> Void) {
        self.onEdit = onEdit
        super.init(frame: .zero)
        setupUI()
        updateView(profile: profile)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView(profile: ProfileInput) {
        let cm = NSLocalizedString("unit_cm", comment: "")
        let kg = NSLocalizedString("unit_kg", comment: "")

        if let height = profile.height, height > 0 {
            updateRow(tag: 0, value: "\(height) \(cm)")
        } else {
            updateRow(tag: 0, value: "-")
        }

        if let weight = profile.weight, weight > 0 {
            updateRow(tag: 1, value: "\(weight) \(kg)")
        } else {
            updateRow(tag: 1, value: "-")
        }

        if let dob = profile.birthday {
            let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
            updateRow(tag: 2, value: "\(age)")
        } else {
            updateRow(tag: 2, value: "-")
        }

        let genderLocalized: String
        switch profile.gender {
        case "Male": genderLocalized = NSLocalizedString("gender_male", comment: "")
        case "Female": genderLocalized = NSLocalizedString("gender_female", comment: "")
        default: genderLocalized = "-"
        }
        updateRow(tag: 3, value: genderLocalized)
    }

    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])

        let titles = [
            NSLocalizedString("height_title", comment: ""),
            NSLocalizedString("weight_title", comment: ""),
            NSLocalizedString("age_title", comment: ""),
            NSLocalizedString("gender_title", comment: "")
        ]

        for i in 0..<titles.count {
            stack.addArrangedSubview(makeRow(title: titles[i], tag: i))
        }
    }

    private func makeRow(title: String, tag: Int) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Avenir", size: 18)
        titleLabel.textColor = .label

        let valueLabel = UILabel()
        valueLabel.font = UIFont(name: "Avenir", size: 18)
        valueLabel.textColor = .secondaryLabel
        valueLabel.tag = 100 + tag

        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("change_button", comment: ""), for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir", size: 16)
        button.tag = tag
        button.addTarget(self, action: #selector(changeTapped(_:)), for: .touchUpInside)

        let hStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, button])
        hStack.axis = .horizontal
        hStack.distribution = .equalSpacing
        hStack.alignment = .center

        return hStack
    }

    private func updateRow(tag: Int, value: String) {
        if let label = stack.viewWithTag(100 + tag) as? UILabel {
            label.text = value
        }
    }

    @objc private func changeTapped(_ sender: UIButton) {
        onEdit?(sender.tag)
    }
}
