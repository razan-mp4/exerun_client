//
//  CyclingMapStatsView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//

import UIKit

class CyclingMapStatsView: UIView {

    private var statsStackView: StatsHorizontalStackView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        self.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white

        statsStackView = StatsHorizontalStackView()
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.configure(with: [
            (numberText: "00:00:00", descriptionText: "Time"),
            (numberText: "0.0 km/h", descriptionText: "Speed"),
            (numberText: "0.0 km", descriptionText: "Distance")
        ])
        addSubview(statsStackView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statsStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            statsStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            statsStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            statsStackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -15)
        ])
    }

    func displayStats(_ model: CyclingSessionModel) {
        statsStackView.updateStats(at: 0, withNumberText: model.time)
        statsStackView.updateStats(at: 1, withNumberText: model.speed)
        statsStackView.updateStats(at: 2, withNumberText: model.distance)
    }

    func updateLabelColors(_ color: UIColor) {
        statsStackView.updateLabelColors(color)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
    }
}
