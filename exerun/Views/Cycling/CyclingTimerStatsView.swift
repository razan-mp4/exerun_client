//
//  CyclingTimerStatsView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//

import UIKit
import AudioToolbox
import AVFoundation

class CyclingTimerStatsView: UIView {

    private var circularProgressView: UIView!
    private var timerLabel: UILabel!
    private var countdownLabel: UILabel!
    private var statusLabel: UILabel!

    private var firstStatsStackView: StatsHorizontalStackView!
    private var secondStatsStackView: StatsHorizontalStackView!

    private var countdownValue: Int = 3
    private var countdownTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private(set) var isCountdownRunning: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.textColor = .systemOrange
        statusLabel.font = UIFont(name: "Avenir", size: 30)
        addSubview(statusLabel)

        circularProgressView = UIView()
        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        circularProgressView.backgroundColor = .clear
        circularProgressView.layer.cornerRadius = 112.5
        circularProgressView.layer.borderWidth = 20
        circularProgressView.layer.borderColor = UIColor.systemOrange.cgColor
        addSubview(circularProgressView)

        timerLabel = UILabel()
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.text = "00:00:00\n0.0 km"
        timerLabel.font = UIFont(name: "Avenir", size: 30)
        timerLabel.textAlignment = .center
        timerLabel.numberOfLines = 2
        circularProgressView.addSubview(timerLabel)

        countdownLabel = UILabel()
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.font = UIFont(name: "Avenir", size: 40)
        countdownLabel.textAlignment = .center
        countdownLabel.isHidden = true
        circularProgressView.addSubview(countdownLabel)

        firstStatsStackView = StatsHorizontalStackView()
        firstStatsStackView.translatesAutoresizingMaskIntoConstraints = false
        firstStatsStackView.configure(with: [
            (numberText: "0.0 km/h", descriptionText: "Max Speed"),
            (numberText: "0 m", descriptionText: "Elevation"),
            (numberText: "0'00''/km", descriptionText: "Avg Pace")
        ])
        addSubview(firstStatsStackView)

        secondStatsStackView = StatsHorizontalStackView()
        secondStatsStackView.translatesAutoresizingMaskIntoConstraints = false
        secondStatsStackView.configure(with: [
            (numberText: "0.0 km/h", descriptionText: "Speed"),
            (numberText: "0 bpm", descriptionText: "Heart Rate"),
            (numberText: "0.0 km/h", descriptionText: "Avg Speed")
        ])
        addSubview(secondStatsStackView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 50),
            statusLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 30),

            circularProgressView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            circularProgressView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -50),
            circularProgressView.widthAnchor.constraint(equalToConstant: 225),
            circularProgressView.heightAnchor.constraint(equalToConstant: 225),

            timerLabel.centerXAnchor.constraint(equalTo: circularProgressView.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: circularProgressView.centerYAnchor),

            countdownLabel.centerXAnchor.constraint(equalTo: circularProgressView.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: circularProgressView.centerYAnchor),

            firstStatsStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            firstStatsStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            firstStatsStackView.topAnchor.constraint(equalTo: circularProgressView.bottomAnchor, constant: 20),

            secondStatsStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            secondStatsStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            secondStatsStackView.topAnchor.constraint(equalTo: firstStatsStackView.bottomAnchor, constant: 20)
        ])
    }

    func displayStats(_ model: CyclingSessionModel) {
        timerLabel.text = "\(model.time)\n\(model.distance)"
        firstStatsStackView.updateStats(at: 0, withNumberText: model.maxSpeed)
        firstStatsStackView.updateStats(at: 1, withNumberText: model.totalElevationGain)
        firstStatsStackView.updateStats(at: 2, withNumberText: model.avgPace)
        secondStatsStackView.updateStats(at: 0, withNumberText: model.speed)
        secondStatsStackView.updateStats(at: 1, withNumberText: model.heartRate)
        secondStatsStackView.updateStats(at: 2, withNumberText: model.avgSpeed)
    }

    func updateLabelColors(_ color: UIColor) {
        timerLabel.textColor = color
        firstStatsStackView.updateLabelColors(color)
        secondStatsStackView.updateLabelColors(color)
    }

    func startCountdown(completion: @escaping () -> Void) {
        countdownValue = 3
        hideStatsLabels(true)
        countdownLabel.isHidden = false
        countdownLabel.text = "\(countdownValue)"
        updateStatus(countdownTime: countdownValue)
        playSoundAndVibrate()

        isCountdownRunning = true

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.countdownValue -= 1
            if self.countdownValue >= 0 {
                self.countdownLabel.text = "\(self.countdownValue)"
                self.updateStatus(countdownTime: self.countdownValue)
                self.playSoundAndVibrate()
            } else {
                self.countdownTimer?.invalidate()
                self.countdownLabel.isHidden = true
                self.hideStatsLabels(false)
                self.isCountdownRunning = false
                completion()
            }
        }
    }

    func updateStatus(countdownTime: Int) {
        switch countdownTime {
        case 3: statusLabel.text = "Ready!"
        case 2: statusLabel.text = "Steady!"
        case 1: statusLabel.text = "Go!"
        default: statusLabel.text = ""
        }
    }

    func stopCountdown() {
        countdownTimer?.invalidate()
        countdownLabel.isHidden = true
        isCountdownRunning = false
        hideStatsLabels(false)
        statusLabel.text = "Paused"
    }

    func showPausedStatus() {
        statusLabel.text = "Paused"
        hideStatsLabels(false)
    }

    private func hideStatsLabels(_ hide: Bool) {
        firstStatsStackView.isHidden = hide
        secondStatsStackView.isHidden = hide
        timerLabel.isHidden = hide
    }

    private func playSoundAndVibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        if let soundURL = Bundle.main.url(forResource: "boop", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Sound error: \(error.localizedDescription)")
            }
        }
    }

    func updateStatusLabelColor(_ color: UIColor) {
        statusLabel.textColor = color
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLabelColors(traitCollection.userInterfaceStyle == .dark ? .white : .black)
    }
}
