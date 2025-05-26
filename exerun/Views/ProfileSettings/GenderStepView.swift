//
//  GenderStepView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 22/4/2025.
//


import UIKit

final class GenderStepView: UIView {
    private let label = UILabel()
    private let segmentedControl: UISegmentedControl
    private let onSelect: (String) -> Void

    // Internal values for the server
    private let genderOptions = [("Male", NSLocalizedString("gender_male", comment: "Male gender")),
                                 ("Female", NSLocalizedString("gender_female", comment: "Female gender"))]

    init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
        self.segmentedControl = UISegmentedControl(items: genderOptions.map { $0.1 }) // Show localized values
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        label.text = NSLocalizedString("select_gender_label", comment: "Prompt to select gender")
        label.font = UIFont(name: "Avenir", size: 20)
        label.textAlignment = .center

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(genderChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

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

        // Initial selection and callback with internal value
        onSelect(genderOptions[segmentedControl.selectedSegmentIndex].0)
    }

    @objc private func genderChanged() {
        let selectedIndex = segmentedControl.selectedSegmentIndex
        let internalValue = genderOptions[selectedIndex].0 // "Male" or "Female"
        onSelect(internalValue)
    }
}
