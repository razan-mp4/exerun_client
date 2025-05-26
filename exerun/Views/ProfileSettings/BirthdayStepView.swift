//
//  AgeStepView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 22/4/2025.
//


import UIKit

final class BirthdayStepView: UIView {
    private let label = UILabel()
    private let datePicker = UIDatePicker()
    private let onSelect: (Date) -> Void

    init(onSelect: @escaping (Date) -> Void) {
        self.onSelect = onSelect
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        label.text = NSLocalizedString("select_birthdate_label", comment: "Prompt to select birthdate")
        label.font = UIFont(name: "Avenir", size: 20)
        label.textAlignment = .center

        // ✅ Configure date picker
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels // 👈 gives the "rotating wheels"
        datePicker.maximumDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())
        datePicker.minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: Date())
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        // Stack
        let stack = UIStackView(arrangedSubviews: [label, datePicker])
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

        onSelect(datePicker.date) // Set initial value immediately
    }

    @objc private func dateChanged() {
        onSelect(datePicker.date)
    }
}
