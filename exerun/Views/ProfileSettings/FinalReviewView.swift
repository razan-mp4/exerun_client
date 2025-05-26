//
//  FinalReviewView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 22/4/2025.
//

import UIKit

final class FinalReviewView: UIView {

    private let stack = UIStackView()
    var onEdit: ((Int) -> Void)?
    var dataProvider: (() -> ProfileOnboardingViewController.ProfileInput)?

    init(dataProvider: @escaping () -> ProfileOnboardingViewController.ProfileInput,
         onEdit: @escaping (Int) -> Void) {
        self.dataProvider = dataProvider
        self.onEdit = onEdit
        super.init(frame: .zero)
        setupUI()
        updateView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView() {
        guard let data = dataProvider?() else { return }

        let cm = NSLocalizedString("unit_cm", comment: "Centimeters unit")
        let kg = NSLocalizedString("unit_kg", comment: "Kilograms unit")

        updateRow(tag: 0, value: "\(data.height ?? 0) \(cm)")
        updateRow(tag: 1, value: "\(data.weight ?? 0) \(kg)")

        if let dob = data.birthday {
            let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
            updateRow(tag: 2, value: "\(age)")
        } else {
            updateRow(tag: 2, value: "-")
        }

        // 👇 Convert stored English gender to localized label
        let genderLocalized: String
        switch data.gender {
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
            NSLocalizedString("height_title", comment: "Height label"),
            NSLocalizedString("weight_title", comment: "Weight label"),
            NSLocalizedString("age_title", comment: "Age label"),
            NSLocalizedString("gender_title", comment: "Gender label")
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
        button.setTitle(NSLocalizedString("change_button", comment: "Edit or change value"), for: .normal)
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
