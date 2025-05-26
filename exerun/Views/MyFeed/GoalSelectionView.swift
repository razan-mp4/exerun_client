//
//  GoalSelectionView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//

import UIKit

final class GoalSelectionView: UIView {
    var onSelect: ((String) -> Void)?

    private var buttons: [UIButton] = []
    private let goals = ["lose_weight", "gain_weight", "keep_form"]
    private var selectedGoal: String = "keep_form"

    init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
        super.init(frame: .zero)
        setupUI()
        selectGoal("keep_form") // Default selection
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "What is your goal?"
        titleLabel.font = UIFont(name: "Avenir", size: 22)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(titleLabel)

        for goal in goals {
            let button = UIButton(type: .system)
            let title = goal.replacingOccurrences(of: "_", with: " ").capitalized
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont(name: "Avenir", size: 20)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 12
            button.backgroundColor = .systemOrange.withAlphaComponent(0.5)
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.tag = buttons.count // index
            button.addTarget(self, action: #selector(goalTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])
    }

    private func selectGoal(_ goal: String) {
        selectedGoal = goal
        for (index, button) in buttons.enumerated() {
            if goals[index] == goal {
                button.backgroundColor = .systemOrange
            } else {
                button.backgroundColor = .systemOrange.withAlphaComponent(0.5)
            }
        }
        onSelect?(goal)
    }

    @objc private func goalTapped(_ sender: UIButton) {
        let goal = goals[sender.tag]
        selectGoal(goal)
    }

    required init?(coder: NSCoder) { fatalError() }
}
