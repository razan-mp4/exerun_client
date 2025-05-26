//
//  CompassView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 25/1/2025.
//

import UIKit
import CoreLocation
import CoreMotion

class CompassView: UIView {
    private var circularProgressView: UIView!
    private var compassElementsView: CompassElementsView!
    private var currentElevationLabel: UILabel!
    private var cardinalDirectionLabel: UILabel!
    private var positionWarningLabel: UILabel! // Label to display the warning
    private let arrowSize: CGFloat = 100
    var statusLabel: UILabel!
    private let motionManager = CMMotionManager()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        updateLabelColors(for: traitCollection.userInterfaceStyle == .dark) // Initialize colors
        startDeviceMotionUpdates() // Start tracking the device's orientation
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        updateLabelColors(for: traitCollection.userInterfaceStyle == .dark) // Initialize colors
        startDeviceMotionUpdates() // Start tracking the device's orientation
    }

    deinit {
        motionManager.stopDeviceMotionUpdates() // Stop updates when the view is deallocated
    }

    private func setupView() {
        backgroundColor = .clear
        
        // Circular Progress View
        setupCircularProgressView()
        
        // Add Tick Marks
        setupTickMarksView()
        
        // Status Label
        setupStatusLabel()
        
        // Current Elevation Label
        setupCurrentElevationLabel()
        
        // Cardinal Direction Label
        setupCardinalDirectionLabel()
        
        // Position Warning Label
        setupPositionWarningLabel()
    }

    private func setupCircularProgressView() {
        circularProgressView = UIView()
        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        circularProgressView.backgroundColor = .clear
        circularProgressView.layer.cornerRadius = 112.5
        circularProgressView.layer.borderWidth = 20
        circularProgressView.layer.borderColor = UIColor.systemOrange.cgColor
        addSubview(circularProgressView)
        
        NSLayoutConstraint.activate([
            circularProgressView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            circularProgressView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -50),
            circularProgressView.widthAnchor.constraint(equalToConstant: 225),
            circularProgressView.heightAnchor.constraint(equalToConstant: 225)
        ])
    }

    private func setupTickMarksView() {
        compassElementsView = CompassElementsView(arrowSize: arrowSize)
        compassElementsView.translatesAutoresizingMaskIntoConstraints = false
        compassElementsView.backgroundColor = .clear
        addSubview(compassElementsView)

        NSLayoutConstraint.activate([
            compassElementsView.centerXAnchor.constraint(equalTo: circularProgressView.centerXAnchor),
            compassElementsView.centerYAnchor.constraint(equalTo: circularProgressView.centerYAnchor),
            compassElementsView.widthAnchor.constraint(equalTo: circularProgressView.widthAnchor, constant: 115),
            compassElementsView.heightAnchor.constraint(equalTo: circularProgressView.heightAnchor, constant: 115)
        ])
    }

    private func setupStatusLabel() {
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.textColor = .systemOrange
        statusLabel.font = UIFont(name: "Avenir", size: 30)
        statusLabel.textColor = .clear
        addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 50),
            statusLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupCurrentElevationLabel() {
        currentElevationLabel = UILabel()
        currentElevationLabel.translatesAutoresizingMaskIntoConstraints = false
        currentElevationLabel.text = "Current Elevation: 0m" // Initial text
        currentElevationLabel.font = UIFont(name: "Avenir", size: 28)
        currentElevationLabel.textAlignment = .center
        currentElevationLabel.textColor = .white
        addSubview(currentElevationLabel)
        
        NSLayoutConstraint.activate([
            currentElevationLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -150),
            currentElevationLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    private func setupCardinalDirectionLabel() {
        cardinalDirectionLabel = UILabel()
        cardinalDirectionLabel.translatesAutoresizingMaskIntoConstraints = false
        cardinalDirectionLabel.text = "N"
        cardinalDirectionLabel.font = UIFont(name: "Avenir", size: 30)
        cardinalDirectionLabel.textAlignment = .center
        cardinalDirectionLabel.textColor = .white
        addSubview(cardinalDirectionLabel)
        
        NSLayoutConstraint.activate([
            cardinalDirectionLabel.bottomAnchor.constraint(equalTo: currentElevationLabel.topAnchor, constant: -10),
            cardinalDirectionLabel.centerXAnchor.constraint(equalTo: currentElevationLabel.centerXAnchor)
        ])
    }

    private func setupPositionWarningLabel() {
        positionWarningLabel = UILabel()
        positionWarningLabel.translatesAutoresizingMaskIntoConstraints = false
        positionWarningLabel.text = "For better accuracy,\nplace the phone horizontally"
        positionWarningLabel.font = UIFont(name: "Avenir", size: 20)
        positionWarningLabel.textAlignment = .center
        positionWarningLabel.numberOfLines = 0
        positionWarningLabel.isHidden = true // Initially hidden

        // Add to view hierarchy
        addSubview(positionWarningLabel)
        
        NSLayoutConstraint.activate([
            positionWarningLabel.bottomAnchor.constraint(equalTo: circularProgressView.topAnchor, constant: -80),
            positionWarningLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            positionWarningLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        ])
    }

    private func updateCardinalDirection(for heading: CLLocationDirection) {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((heading + 22.5) / 45.0) % 8
        let cardinalDirection = directions[index]
        
        // Format the heading to one decimal place
        let formattedHeading = String(format: "%.1f", heading)
        
        // Update the label to show both direction and heading
        cardinalDirectionLabel.text = "\(cardinalDirection) \(formattedHeading)°"
    }

    func updateStatusLabel(paused: Bool) {
        statusLabel.text = paused ? "Paused" : ""
        statusLabel.textColor = paused ? .systemOrange : .clear
    }
    
    func updateHeading(heading: CLLocationDirection) {
        let radians = CGFloat(heading) * (.pi / 180)
        updateCardinalDirection(for: heading)
        
        // Update arrow rotation
        compassElementsView.updateArrowRotation(radians: radians)
    }

    func updateCurrentElevation(elevation: Double) {
        currentElevationLabel.text = "Current Elevation: \(Int(elevation))m"
    }
    
    // Update label colors for light/dark mode
    func updateLabelColors(for isDarkMode: Bool) {
        let labelColor: UIColor = isDarkMode ? .white : .black
        currentElevationLabel.textColor = labelColor
        cardinalDirectionLabel.textColor = labelColor
        positionWarningLabel.textColor = labelColor // Text color adapts to mode
        compassElementsView.updateTickMarkColors(for: isDarkMode) // Update tick mark colors
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLabelColors(for: traitCollection.userInterfaceStyle == .dark)
    }

    private func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available.")
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.1 // Update interval in seconds
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else {
                print("Error receiving motion updates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let pitch = abs(motion.attitude.pitch) // Measure tilt
            let roll = abs(motion.attitude.roll)

            // Show warning if phone is not horizontal
            if pitch > 0.2 || roll > 0.2 { // Adjust threshold as needed
                self.positionWarningLabel.isHidden = false
            } else {
                self.positionWarningLabel.isHidden = true
            }
        }
    }
}

