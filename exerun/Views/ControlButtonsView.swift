//
//  ControlButtonsView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 29/8/2024.
//

import UIKit

class ControlButtonsView: UIView {
    
    var stopButton: UIButton!
    var finishButton: UIButton!
    var continueButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // Create Stop button
        stopButton = UIButton(type: .system)
        stopButton.setTitle("Stop", for: .normal)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.backgroundColor = .systemOrange
        stopButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.layer.cornerRadius = 20
        addSubview(stopButton)
        
        // Create Finish button
        finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish", for: .normal)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.backgroundColor = .systemGray4
        finishButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        finishButton.layer.cornerRadius = 20
        finishButton.isHidden = true // Initially hidden
        addSubview(finishButton)
        
        // Create Continue button
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = .systemOrange
        continueButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.layer.cornerRadius = 20
        continueButton.isHidden = true // Initially hidden
        addSubview(continueButton)
        
        // Add constraints for the buttons
        NSLayoutConstraint.activate([
            stopButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stopButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stopButton.widthAnchor.constraint(equalToConstant: 100),
            stopButton.heightAnchor.constraint(equalToConstant: 40),
            
            finishButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: -70),
            finishButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            finishButton.widthAnchor.constraint(equalToConstant: 100),
            finishButton.heightAnchor.constraint(equalToConstant: 40),
            
            continueButton.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 70),
            continueButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            continueButton.widthAnchor.constraint(equalToConstant: 100),
            continueButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func showFinishAndContinueButtons() {
        stopButton.isHidden = true
        finishButton.isHidden = false
        continueButton.isHidden = false
    }

    func showStopButton() {
        stopButton.isHidden = false
        finishButton.isHidden = true
        continueButton.isHidden = true
    }
}
