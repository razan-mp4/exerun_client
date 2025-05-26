//
//  TrainingDaysView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//

import UIKit

final class TrainingDaysView: UIView {
    var onSelect: ((Int) -> Void)?

    init(onSelect: @escaping (Int) -> Void) {
        self.onSelect = onSelect
        super.init(frame: .zero)
        setupUI()
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "How often do you want to train?"
        titleLabel.font = UIFont(name: "Avenir", size: 22)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(picker)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            picker.centerXAnchor.constraint(equalTo: centerXAnchor),
            picker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20)
        ])

        // 🔽 Select 3rd row (index 2) by default
        picker.selectRow(2, inComponent: 0, animated: false)
        onSelect?(3) // Notify default selection
    }



    required init?(coder: NSCoder) { fatalError() }
}

extension TrainingDaysView: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { 5 }
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title = "\(row + 1) times per week"
        return NSAttributedString(string: title, attributes: [.foregroundColor: UIColor.white])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        onSelect?(row + 1)
    }
}

