//
//  GymPlanCell.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//

import UIKit

final class GymPlanCell: UITableViewCell {

    private let cardView = UIView()
    let nameLabel = UILabel()
    let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear  // so spacing is visible
        selectionStyle = .none

        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        cardView.layer.cornerRadius = 12
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        nameLabel.font = UIFont(name: "Avenir", size: 18)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont(name: "Avenir", size: 16)
        dateLabel.textColor = .white
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(nameLabel)
        cardView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            // Card view padding from cell edges
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            // Labels inside card view
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            dateLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            dateLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    func configure(with plan: GymPlanEntity) {
        nameLabel.text = plan.name ?? "Unnamed Plan"

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateLabel.text = formatter.string(from: plan.createdAt ?? Date())
    }
}
