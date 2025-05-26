//
//  SetsTimerView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 27/10/2024.
//


import UIKit
import AudioToolbox
import AVFoundation

class SetsTimerView: UIView {
    
    var circularProgressView: CircularProgressView!
    var statusLabel: UILabel!
    var setsLeftLabel: UILabel!
    var timeLabel: UILabel!
    
    // Audio player for sounds
    var audioPlayer: AVAudioPlayer?
    
    // Time tracking properties
    var timeTracker: QuickWorkoutModel!
    
    // Timer properties
    var timer: Timer?
    var currentTime: TimeInterval = 0.0
    var isPaused: Bool = false // New property to track pause state
    
    // Completion handler to notify when the workout is finished
    var workoutFinished: (() -> Void)?
    
    // Initialize with a TimeTrackerModel
    init(timeTracker: QuickWorkoutModel) {
        self.timeTracker = timeTracker
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        // Remove startMainTimer() from here
        updateStatus(isWorkTime: timeTracker.isWorkTime)
        updateSetsLeftLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // timeTracker will need to be set after initialization
        setupViews()
        setupConstraints()
    }
    
    private func setupViews() {
        // Create and add the circular progress view
        circularProgressView = CircularProgressView()
        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circularProgressView)
        
        // Add status label at the top
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.textColor = .systemOrange
        statusLabel.font = UIFont(name: "Avenir", size: 25)
        addSubview(statusLabel)
        
        // Add time label in the center
        timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont(name: "Avenir", size: 30)
        addSubview(timeLabel)
        
        // Add sets left label
        setsLeftLabel = UILabel()
        setsLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        setsLeftLabel.textAlignment = .center
        setsLeftLabel.font = UIFont(name: "Avenir", size: 16)
        addSubview(setsLeftLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Status label at the top
            statusLabel.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // Circular progress view in the center
            circularProgressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circularProgressView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 15),
            circularProgressView.widthAnchor.constraint(equalToConstant: 210),
            circularProgressView.heightAnchor.constraint(equalToConstant: 210),
            
            // Time label in the center of the progress view
            timeLabel.centerXAnchor.constraint(equalTo: circularProgressView.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: circularProgressView.centerYAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 100),
            timeLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // Sets left label below the circular progress view
            setsLeftLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 90),
            setsLeftLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            setsLeftLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            setsLeftLabel.heightAnchor.constraint(equalToConstant: 220)
        ])
    }
    
    // MARK: - Timer Control Methods
    
    func startMainTimer() {
        invalidateTimer()  // Safely invalidate any existing timer
        isPaused = false
        updateStatus(isWorkTime: timeTracker.isWorkTime)
        updateSetsLeftLabel()
        updateTimeLabel()
        // If starting fresh, reset currentTime and progress
        if currentTime == 0.0 {
            circularProgressView.progress = 0.0
        }
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    func pauseTimer() {
        isPaused = true
        invalidateTimer()
    }
    
    func resumeTimer() {
        if isPaused {
            isPaused = false
            // Resume the timer without resetting currentTime
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        }
    }
    
    // MARK: - Timer Update Method
    
    @objc private func updateTimer() {
        currentTime += 1.0
        guard let currentIntervalTime = timeTracker.currentIntervalTime else {
            print("currentIntervalTime is nil")
            return
        }
        let progress = Float(currentTime / currentIntervalTime)
        circularProgressView.progress = CGFloat(progress)
        updateTimeLabel()
        
        if currentTime >= currentIntervalTime {
            invalidateTimer()
            playSoundAndVibrate()
            
            timeTracker.isWorkTime.toggle()
            if timeTracker.isWorkTime {
                timeTracker.currentSet += 1
            }
            if timeTracker.currentSet >= timeTracker.totalSets {
                // Notify workout is finished
                workoutFinished?()
                return
            }
            currentTime = 0.0
            startMainTimer()
        }
    }

    
    // MARK: - Helper Methods
    
    private func updateTimeLabel() {
        guard let currentIntervalTime = timeTracker.currentIntervalTime else {
            print("currentIntervalTime is nil")
            return
        }
        let timeLeft = currentIntervalTime - currentTime
        let minutes = Int(timeLeft) / 60
        let seconds = Int(timeLeft) % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateSetsLeftLabel() {
        let setsLeft = timeTracker.totalSets - timeTracker.currentSet
        setsLeftLabel.text = "Sets Left: \(setsLeft)"
    }
    
    private func updateStatus(isWorkTime: Bool) {
        let newStatus = isWorkTime ? "Work Time" : "Rest Time"
        updateStatusLabel(newStatus)
    }
    
    private func updateStatusLabel(_ newStatus: String) {
        if statusLabel.text != newStatus && !newStatus.isEmpty {
            UIView.transition(with: statusLabel, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.statusLabel.text = newStatus
            })
        }
    }
    
    private func playSoundAndVibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        guard let soundURL = Bundle.main.url(forResource: "boop", withExtension: "mp3") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateLabelColors() {
        timeLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        statusLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .systemOrange
        setsLeftLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
    }
    
    deinit {
        invalidateTimer()
    }
}
