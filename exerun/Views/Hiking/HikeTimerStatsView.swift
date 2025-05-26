//
//  HikeTimerStatsView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/1/2025.
//

import UIKit
import AudioToolbox
import AVFoundation

class HikeTimerStatsView: UIView {
    
    private var circularProgressView: UIView!
    private var timerLabel: UILabel!
    private var countdownLabel: UILabel!
    private var statusLabel: UILabel!
    
    private var firstStatsStackView: StatsHorizontalStackView!
    private var secondStatsStackView: StatsHorizontalStackView!
    private var thirdStatsStackView: StatsHorizontalStackView!
    
    private var countdownValue: Int = 3
    private var countdownTimer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private(set) var isCountdownRunning: Bool = false  // Track countdown state

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        // Status Label (at the top)
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.textColor = .systemOrange
        statusLabel.font = UIFont(name: "Avenir", size: 30)
        addSubview(statusLabel)
        
        // Circular Timer View
        circularProgressView = UIView()
        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        circularProgressView.backgroundColor = .clear
        circularProgressView.layer.cornerRadius = 112.5
        circularProgressView.layer.borderWidth = 20
        circularProgressView.layer.borderColor = UIColor.systemOrange.cgColor
        addSubview(circularProgressView)
        
        // Timer Label (inside the circular view)
        timerLabel = UILabel()
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.text = "00:00:00\n0.0 km"
        timerLabel.font = UIFont(name: "Avenir", size: 30)
        timerLabel.textAlignment = .center
        timerLabel.numberOfLines = 2
        circularProgressView.addSubview(timerLabel)
        
        // Countdown Label (initially hidden)
        countdownLabel = UILabel()
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.font = UIFont(name: "Avenir", size: 40)
        countdownLabel.textAlignment = .center
        countdownLabel.isHidden = true
        circularProgressView.addSubview(countdownLabel)
        
        // Initialize the first StatsHorizontalStackView for Pace, Elevation, and Avg Pace
        firstStatsStackView = StatsHorizontalStackView()
        firstStatsStackView.translatesAutoresizingMaskIntoConstraints = false
        firstStatsStackView.configure(with: [
            (numberText: "0.0 km/h", descriptionText: "Max Speed"),
            (numberText: "0.0 km/h", descriptionText: "Speed"),
            (numberText: "0'00''/km", descriptionText: "Avg Pace")
        ])
        addSubview(firstStatsStackView)
        
        // Initialize the second StatsHorizontalStackView for Speed, Heart Rate, and Avg Speed
        secondStatsStackView = StatsHorizontalStackView()
        secondStatsStackView.translatesAutoresizingMaskIntoConstraints = false
        secondStatsStackView.configure(with: [
            (numberText: "0 bpm", descriptionText: "Avg Heart Rate"),
            (numberText: "0 bpm", descriptionText: "Heart Rate"),
            (numberText: "0.0 km/h", descriptionText: "Avg Speed")
        ])
        addSubview(secondStatsStackView)
        
        // Initialize the third StatsHorizontalStackView for Speed, Heart Rate, and Avg Speed
        thirdStatsStackView = StatsHorizontalStackView()
        thirdStatsStackView.translatesAutoresizingMaskIntoConstraints = false
        thirdStatsStackView.configure(with: [
            (numberText: "0 m", descriptionText: "Min Elevation"),
            (numberText: "0 m", descriptionText: "Elevation Gain"),
            (numberText: "0 m", descriptionText: "Max Elevation")
        ])
        addSubview(thirdStatsStackView)
        
        // Set constraints for the views
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Status label constraints
            statusLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 50),
            statusLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // Circular Timer View constraints
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
            secondStatsStackView.topAnchor.constraint(equalTo: firstStatsStackView.bottomAnchor, constant: 20),
            
            thirdStatsStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            thirdStatsStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            thirdStatsStackView.bottomAnchor.constraint(equalTo: circularProgressView.topAnchor, constant: -25)
        ])
    }

    func displayStats(_ hikeSessionModel: HikeSessionModel) {
        timerLabel.text = "\(hikeSessionModel.time)\n\(hikeSessionModel.distance)"
        firstStatsStackView.updateStats(at: 0, withNumberText: hikeSessionModel.maxSpeed)
        firstStatsStackView.updateStats(at: 1, withNumberText: hikeSessionModel.speed)
        firstStatsStackView.updateStats(at: 2, withNumberText: hikeSessionModel.avgPace)
        secondStatsStackView.updateStats(at: 0, withNumberText: hikeSessionModel.averageHeartRate)
        secondStatsStackView.updateStats(at: 1, withNumberText: hikeSessionModel.heartRate)
        secondStatsStackView.updateStats(at: 2, withNumberText: hikeSessionModel.avgSpeed)
        thirdStatsStackView.updateStats(at: 0, withNumberText: hikeSessionModel.minElevation)
        thirdStatsStackView.updateStats(at: 1, withNumberText: hikeSessionModel.totalElevationGain)
        thirdStatsStackView.updateStats(at: 2, withNumberText: hikeSessionModel.maxElevation)
    }

    func updateLabelColors(_ color: UIColor) {
        timerLabel.textColor = color
        firstStatsStackView.updateLabelColors(color)
        secondStatsStackView.updateLabelColors(color)
        thirdStatsStackView.updateLabelColors(color)
    }
    
    func startCountdown(completion: @escaping () -> Void) {
        countdownValue = 3  // Reset the countdown value to 3
        hideStatsLabels(true)
        countdownLabel.isHidden = false
        countdownLabel.text = "\(countdownValue)"
        
        // Set initial status to "Ready!"
        updateStatus(countdownTime: countdownValue)
        playSoundAndVibrate()
        
        isCountdownRunning = true  // Countdown is now running

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
                self.isCountdownRunning = false  // Countdown is finished
                completion()
            }
        }
    }

    func updateStatus(countdownTime: Int) {
        switch countdownTime {
        case 3:
            statusLabel.text = "Ready!"
        case 2:
            statusLabel.text = "Steady!"
        case 1:
            statusLabel.text = "Go!"
        default:
            statusLabel.text = ""
        }
    }
    
    private func playSoundAndVibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        if let soundURL = Bundle.main.url(forResource: "boop", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Failed to play sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found")
        }
    }

    func stopCountdown() {
        countdownTimer?.invalidate()
        countdownLabel.isHidden = true
        isCountdownRunning = false  // Countdown is stopped
        
        // Show all statistic labels
        hideStatsLabels(false)
        
        // Optionally update the status label
        statusLabel.text = "Paused"
    }

    func continueCountdown(completion: @escaping () -> Void) {
        countdownValue = 3  // Reset the countdown value to 3
        countdownLabel.isHidden = false
        updateStatus(countdownTime: countdownValue)  // Show "Ready!" immediately
        playSoundAndVibrate()
        
        startCountdown(completion: completion)
    }

    private func hideStatsLabels(_ hide: Bool) {
        firstStatsStackView.isHidden = hide
        secondStatsStackView.isHidden = hide
        thirdStatsStackView.isHidden = hide
        timerLabel.isHidden = hide
    }
    
    func showPausedStatus() {
        statusLabel.text = "Paused"
        hideStatsLabels(false)  // Show all statistic labels
    }

    func updateStatusLabelColor(_ color: UIColor) {
        statusLabel.textColor = color
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLabelColors(traitCollection.userInterfaceStyle == .dark ? .white : .black)
    }
}
