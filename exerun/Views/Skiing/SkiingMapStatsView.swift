//
//  SkiingMapStatsView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 30/1/2025.
//

import UIKit

class SkiingMapStatsView: UIView {

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
        // Set the background color based on the current interface style
        self.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white

        // Initialize the StatsHorizontalStackView for Time, Speed, and Distance
        statsStackView = StatsHorizontalStackView()
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.configure(with: [
            (numberText: "00:00:00", descriptionText: "Time"),
            (numberText: "0.0 km/h", descriptionText: "Speed"),
            (numberText: "0.0 km", descriptionText: "Distance")
        ])
        addSubview(statsStackView)

        // Set constraints for the view
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Align the StatsHorizontalStackView to the top with a padding of 15 points
            statsStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            statsStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            statsStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            statsStackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -15)
        ])
    }

    // Method to display the stats using RunSessionModel
    func displayStats(_ skiingSessionModel: SkiingSessionModel) {
        statsStackView.updateStats(at: 0, withNumberText: skiingSessionModel.time)
        statsStackView.updateStats(at: 1, withNumberText: skiingSessionModel.speed)
        statsStackView.updateStats(at: 2, withNumberText: skiingSessionModel.distance)
    }
    
    // Method to update label colors when interface style changes
    func updateLabelColors(_ color: UIColor) {
        statsStackView.updateLabelColors(color)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
    }
}
