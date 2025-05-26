//
//  SetsRunViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 11/8/2024.
//

import UIKit
import CoreLocation
import AudioToolbox
import AVFoundation

class SetsRunViewController: FreeRunViewController {
    
    // MARK: - Additional UI Components
    private var setsTimerView: SetsTimerView!
    
    private var currentViewIndex: Int = 0
    
    // TimeTrackerModel instance
    var timeTracker: QuickWorkoutModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure timeTracker is set
        guard timeTracker != nil else {
            fatalError("TimeTrackerModel not set")
        }
        
        // Adjust circle indicators for three views
        circleIndicatorsView.numberOfIndicators = 3
        
        // Setup setsTimerView with the timeTracker
        setupSetsTimerView()
        
        // Ensure the initial view is correctly displayed
        switchToView(at: currentViewIndex)
        
        // Set the workout finished handler
        setsTimerView.workoutFinished = { [weak self] in
            self?.handleWorkoutCompletion()
        }
    }

    
    // Override startWorkout plus to start the sets timer after the initial countdown
    override func startWorkout() {
        super.startWorkout()
        setsTimerView.startMainTimer() // Start the sets timer
        currentViewIndex = 1
        switchToView(at: currentViewIndex)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update page indicators with the correct currentViewIndex
        updatePageIndicators(activeIndex: currentViewIndex)
    }
    
    // MARK: - Setup SetsTimerView
    private func setupSetsTimerView() {
        setsTimerView = SetsTimerView(timeTracker: timeTracker)
        setsTimerView.translatesAutoresizingMaskIntoConstraints = false
        setsTimerView.alpha = 0 // Initially hidden
        view.insertSubview(setsTimerView, belowSubview: controlButtonsView)
        
        // Add constraints for setsTimerView
        NSLayoutConstraint.activate([
            setsTimerView.topAnchor.constraint(equalTo: view.topAnchor),
            setsTimerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            setsTimerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            setsTimerView.bottomAnchor.constraint(equalTo: controlButtonsView.topAnchor) // Adjusted constraint
        ])
    }
    
    // MARK: - Override Gesture Handling
    override func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard isSwipeEnabled else { return }
        if gesture.direction == .left {
            if currentViewIndex < 2 { // Maximum index is 2
                currentViewIndex += 1
                switchToView(at: currentViewIndex)
            }
        } else if gesture.direction == .right {
            if currentViewIndex > 0 { // Minimum index is 0
                currentViewIndex -= 1
                switchToView(at: currentViewIndex)
            }
        }
    }
    
    // MARK: - View Switching Logic
    private func switchToView(at index: Int) {
        UIView.animate(withDuration: 0.3, animations: {
            self.timerStatsView.alpha = (index == 0) ? 1 : 0
            self.setsTimerView.alpha = (index == 1) ? 1 : 0
            self.mapViewContainer.alpha = (index == 2) ? 1 : 0
        }) { _ in
            self.updateAllStatistics()
            self.updatePageIndicators(activeIndex: index)
        }
    }
    
    // MARK: - Override Button Actions
    override func stopButtonTapped() {
        super.stopButtonTapped()
        
        // Pause the sets timer
        setsTimerView.pauseTimer()
    }
    
    override func continueButtonTapped() {
        controlButtonsView.showStopButton()

        // Start the countdown on timerStatsView if not already visible
        if timerStatsView.alpha == 0 {
            currentViewIndex = 0
            switchToView(at: currentViewIndex)
        }

        // Hide indicators and disable swipe gestures during countdown
        hideCircleIndicatorsView()
        enableSwipeGestures(false)

        // Start the countdown with a completion handler to switch to setsTimerView
        timerStatsView.startCountdown { [weak self] in
            guard let self = self else { return }
            
            // Show indicators and enable swipe gestures after countdown finishes
            self.showCircleIndicatorsView()
            self.enableSwipeGestures(true)
            
            // Switch to setsTimerView after countdown finishes
            self.currentViewIndex = 1
            self.switchToView(at: self.currentViewIndex)
            
            // Resume the SetsTimerView timer
            self.setsTimerView.resumeTimer()
            
            // Start the workout routine after switching to setsTimerView
            self.startWorkout()
        }
    }

    
    override func finishButtonTapped() {
        // Stop the workout
        updateTimer?.invalidate()
        locationManager.stopTracking()
        setsTimerView.pauseTimer()
        isPaused = true

        // Perform the segue to the next screen
        performSegue(withIdentifier: "SetsRunFinishedSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SetsRunFinishedSegue",
           let destinationVC = segue.destination as? SetsRunFinishedViewController { // Update to WorkOutFinishedViewController
            // Pass workout data
            destinationVC.runSessionModel = runSessionModel
            destinationVC.segments = mapViewContainer.getSegments() // Pass coordinates
            destinationVC.timeTracker = timeTracker
        }
    }
    
    // MARK: - Handle Workout Completion
    private func handleWorkoutCompletion() {
        // Stop the workout
        updateTimer?.invalidate()
        locationManager.stopTracking()
        setsTimerView.pauseTimer()
        isPaused = true

        // Navigate to the workout finished screen
        performSegue(withIdentifier: "SetsRunFinishedSegue", sender: self)
    }

    
    // MARK: - Override Statistics Update
    override func updateAllStatistics() {
        super.updateAllStatistics()
        // Update setsTimerView if necessary
        // setsTimerView.updateUI() // If you have a method to update UI elements
    }
    
    // MARK: - Trait Collection Changes
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePageIndicators(activeIndex: currentViewIndex)
        setsTimerView.updateLabelColors()
    }
}
