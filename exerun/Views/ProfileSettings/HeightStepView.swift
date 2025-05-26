//
//  HeightStepView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 22/4/2025.
//


import UIKit

final class HeightStepView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    private let picker = UIPickerView()
    private let label = UILabel()
    private var values = Array(100...250)
    private let onSelect: (Int) -> Void

    init(onSelect: @escaping (Int) -> Void) {
        self.onSelect = onSelect
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        picker.dataSource = self
        picker.delegate = self

        label.text = NSLocalizedString("choose_height_label", comment: "Prompt to choose user height in cm")
        label.font = UIFont(name: "Avenir", size: 20)
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [label, picker])
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
        
        // 👇 Set initial value
        picker.selectRow(70, inComponent: 0, animated: false) // 70 → index of 170cm in values
        onSelect(values[70])
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { values.count }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let unit = NSLocalizedString("height_unit_cm", comment: "Centimeters unit label")
        return "\(values[row]) \(unit)"

    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        onSelect(values[row])
    }
}
