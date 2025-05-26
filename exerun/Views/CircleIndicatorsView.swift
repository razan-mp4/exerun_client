//
//  CircleIndicatorsView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 29/8/2024.
//

import UIKit

class CircleIndicatorsView: UIView {
    private var indicators: [UIView] = []
    var numberOfIndicators: Int = 2 {
        didSet {
            setupView()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // Remove existing indicators before setting up new ones
        indicators.forEach { $0.removeFromSuperview() }
        indicators.removeAll()

        // Create indicators based on the specified number
        for _ in 0..<numberOfIndicators {
            let indicator = createCircleIndicator()
            indicators.append(indicator)
        }

        // Set up the stack view to layout indicators
        let stackView = UIStackView(arrangedSubviews: indicators)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Set constraints for each indicator
        indicators.forEach { indicator in
            indicator.widthAnchor.constraint(equalToConstant: 10).isActive = true
            indicator.heightAnchor.constraint(equalToConstant: 10).isActive = true
        }

        // Set the first indicator as active initially
        updatePageIndicators(activeIndex: 0)
    }

    private func createCircleIndicator() -> UIView {
        let circle = UIView()
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.layer.cornerRadius = 5
        circle.backgroundColor = .gray // Default color for inactive circles
        return circle
    }

    func updatePageIndicators(activeIndex: Int) {
        let activeColor = UIColor.systemOrange
        let inactiveColor = UIColor.gray

        for (index, indicator) in indicators.enumerated() {
            indicator.backgroundColor = index == activeIndex ? activeColor : inactiveColor
        }
    }
}
