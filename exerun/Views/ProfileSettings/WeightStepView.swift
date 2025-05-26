//
//  WeightStepView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 22/4/2025.
//


import UIKit

final class WeightStepView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    private let picker = UIPickerView()
    private let label = UILabel()
    private var values = Array(30...200)
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

        label.text = NSLocalizedString("choose_weight_label", comment: "Prompt to choose user weight in kg")
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
        
        picker.selectRow(35, inComponent: 0, animated: false) // 35 → 65kg
        onSelect(values[35])

    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { values.count }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let unit = NSLocalizedString("weight_unit_kg", comment: "Kilograms unit label")
        return "\(values[row]) \(unit)"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        onSelect(values[row])
    }
}

