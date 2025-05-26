//
//  CountdownView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 2/9/2024.
//

import UIKit

class CountdownView: UIView {

    private var countdownLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        countdownLabel = UILabel()
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.font = UIFont(name: "Avenir", size: 60)
        countdownLabel.textAlignment = .center
        countdownLabel.textColor = .systemOrange
        addSubview(countdownLabel)

        NSLayoutConstraint.activate([
            countdownLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    func startCountdown(from start: Int, completion: @escaping () -> Void) {
        var currentCount = start
        countdownLabel.text = "\(currentCount)"
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            currentCount -= 1
            if currentCount > 0 {
                self.countdownLabel.text = "\(currentCount)"
            } else {
                timer.invalidate()
                self.removeFromSuperview()
                completion()
            }
        }
    }
}
