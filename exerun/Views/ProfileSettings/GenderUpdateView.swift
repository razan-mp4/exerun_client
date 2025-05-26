//
//  GenderUpdateView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 29/4/2025.
//

import UIKit

final class GenderUpdateView: UIView {
    private let label = UILabel()
    private let segmentedControl: UISegmentedControl
    private let onSelect: (String) -> Void

    private let genderOptions = [("Male", NSLocalizedString("gender_male", comment: "Male gender")),
                                 ("Female", NSLocalizedString("gender_female", comment: "Female gender"))]

    init(initialGender: String?, onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
        self.segmentedControl = UISegmentedControl(items: genderOptions.map { $0.1 })
        super.init(frame: .zero)
        setup()

        if let gender = initialGender, let index = genderOptions.firstIndex(where: { $0.0 == gender }) {
            segmentedControl.selectedSegmentIndex = index
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        label.text = NSLocalizedString("select_gender_label", comment: "Prompt to select gender")
        label.font = UIFont(name: "Avenir", size: 20)
        label.textAlignment = .center

        segmentedControl.addTarget(self, action: #selector(genderChanged), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [label, segmentedControl])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    @objc private func genderChanged() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        let internalValue = genderOptions[selectedIndex].0 // "Male" or "Female"
        onSelect(internalValue)
    }
}
