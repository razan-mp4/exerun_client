//
//  TimerViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/1/2024.
//

import UIKit
import AudioToolbox
import AVFoundation

class TimerViewController: UIViewController {
    
    var timeTracker: QuickWorkoutModel!
    
    var circularProgressView: CircularProgressView!
    var statusLabel: UILabel!
    var setsLeftLabel: UILabel!
    var timeLabel: UILabel!
    
    var controlButtonsView: ControlButtonsView!
    
    var audioPlayer: AVAudioPlayer?
    
    var isTimerPaused = false
    var isCountDown = true
    
    var timer: Timer?
    var currentTime: TimeInterval = 0.0
    private let initialCountdownTime: TimeInterval = 4.0
    var countdownTime: TimeInterval = 4.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and add the circular progress view to your view hierarchy
        circularProgressView = CircularProgressView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        circularProgressView.center = view.center
        view.addSubview(circularProgressView)
        
        // Add a label at the top
        statusLabel = UILabel(frame: CGRect(x: 0, y: 50, width: view.bounds.width, height: 30))
        statusLabel.textAlignment = .center
        statusLabel.textColor = .systemOrange
        statusLabel.font = UIFont(name: "Avenir", size: 25)
        view.addSubview(statusLabel)
        
        // Add a label in the center to display the time left
        timeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        timeLabel.center = circularProgressView.center
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont(name: "Avenir", size: 30)
        view.addSubview(timeLabel)
        
        // Add the ControlButtonsView for managing the buttons
        controlButtonsView = ControlButtonsView()
        controlButtonsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlButtonsView)
        
        // Set up button actions
        setupButtonActions()
        
        // Add a "Sets Left" label between the "Stop" button and circularProgressView
        setsLeftLabel = UILabel()
        setsLeftLabel.text = ""
        setsLeftLabel.font = UIFont(name: "Avenir", size: 16)
        setsLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(setsLeftLabel)
        
        // Add constraints for the ControlButtonsView, Sets Left label, and other views
        setupConstraints()
        
        // Set initial status
        updateStatus(isWorkTime: timeTracker.isWorkTime, countdownStartStop: true, countdownTime: countdownTime)
        
        // Start the timer for countdown on view load
        startCountdownTimer()
    }
    
    private func setupButtonActions() {
        controlButtonsView.stopButton.addTarget(self, action: #selector(stopTimer), for: .touchUpInside)
        controlButtonsView.finishButton.addTarget(self, action: #selector(finishTimer), for: .touchUpInside)
        controlButtonsView.continueButton.addTarget(self, action: #selector(continueTimer), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ControlButtonsView constraints
            controlButtonsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            controlButtonsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlButtonsView.widthAnchor.constraint(equalTo: view.widthAnchor),
            controlButtonsView.heightAnchor.constraint(equalToConstant: 50),
            
            // Sets Left label constraints
            setsLeftLabel.bottomAnchor.constraint(equalTo: controlButtonsView.topAnchor, constant: -20),
            setsLeftLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func updateStatus(isWorkTime: Bool, countdownStartStop: Bool, countdownTime: TimeInterval = 0.0) {
        let newStatus: String
        
        isCountDown = countdownStartStop
        
        if isCountDown {
            newStatus = countdownStatus(for: countdownTime)
            if newStatus != "" {
                playSoundAndVibrate()
            }
        } else {
            newStatus = isWorkTime ? "Work Time" : "Rest Time"
            playSoundAndVibrate()
        }

        updateStatusLabel(newStatus)
    }

    private func countdownStatus(for time: TimeInterval) -> String {
        switch time {
        case 3:
            return "Ready!"
        case 2:
            return "Steady!"
        case 1:
            return "Go!"
        default:
            return ""
        }
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
    
    private func startCountdownTimer() {
        invalidateTimer()  // Safely invalidate any existing timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdownTimer), userInfo: nil, repeats: true)
    }
    
    @objc private func updateCountdownTimer() {
        countdownTime -= 1.0
        
        updateStatus(isWorkTime: true, countdownStartStop: true, countdownTime: countdownTime)
        
        let roundedSeconds = Int(countdownTime.rounded())
        
        UIView.transition(with: timeLabel, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.timeLabel.text = String(roundedSeconds)
        }, completion: nil)
        
        let progress = Float(countdownTime / 3.0)
        circularProgressView.progress = CGFloat(1.0 - progress)
        
        if countdownTime <= 0 {
            invalidateTimer()
            updateStatus(isWorkTime: true, countdownStartStop: false)
            startMainTimer()
        }
    }
    
    private func startMainTimer() {
        invalidateTimer()  // Safely invalidate any existing timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc private func updateTimer() {
        currentTime += 1.0
        let progress = Float(currentTime / timeTracker.currentIntervalTime)
        circularProgressView.progress = CGFloat(progress)
        updateTimeLabel()
        updateSetsLeftLabel()
        
        if currentTime >= timeTracker.currentIntervalTime {
            invalidateTimer()
            
            timeTracker.isWorkTime = !timeTracker.isWorkTime
            if timeTracker.isWorkTime {
                timeTracker.currentSet += 1
            }
            if timeTracker.currentSet == timeTracker.totalSets {
                performSegue(withIdentifier: "QuickWorkOutFinishedSegue", sender: self)
                return
            }
            updateStatus(isWorkTime: timeTracker.isWorkTime, countdownStartStop: false)
            currentTime = 0.0
            startMainTimer()
        }
    }
    
    private func updateTimeLabel() {
        let timeLeft = timeTracker.currentIntervalTime - currentTime
        let minutes = Int(timeLeft) / 60
        let seconds = Int(timeLeft) % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLabelColor()
    }
    
    private func updateLabelColor() {
        timeLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        statusLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .systemOrange
        setsLeftLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
    }
    
    @objc private func stopTimer() {
        invalidateTimer()
        controlButtonsView.showFinishAndContinueButtons()
    }
    
    @objc private func finishTimer() {
        performSegue(withIdentifier: "QuickWorkOutFinishedSegue", sender: self)
        stopAllOperations()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "QuickWorkOutFinishedSegue",
           let destinationVC = segue.destination as? QuickWorkOutFinishedViewController {
            // Pass workout data
            destinationVC.timeTracker = timeTracker
        }
    }
    
    @objc private func continueTimer() {
        countdownTime = initialCountdownTime  // Reset the countdown time
        startCountdownTimer() // Start the countdown when continue is pressed
        controlButtonsView.showStopButton()
    }
    
    private func updateSetsLeftLabel() {
        let setsLeft = timeTracker.totalSets - timeTracker.currentSet
        setsLeftLabel.text = "Sets Left: \(setsLeft)"
    }
    
    func stopAllOperations() {
        invalidateTimer()
    }
    
    
    
    deinit {
        invalidateTimer()
    }
}
