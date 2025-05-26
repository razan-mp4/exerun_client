//
//  FreeRunViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/8/2024.
//

import UIKit
import CoreLocation

class FreeRunViewController: UIViewController {

    // MARK: - UI Components
    var timerStatsView: RunTimerStatsView!
    var mapViewContainer: MapTrackingView!
    var mapStatsView: RunMapStatsView!
    var controlButtonsView: ControlButtonsView!
    var circleIndicatorsView: CircleIndicatorsView!

    var runSessionModel: RunSessionModel!
    var locationManager: RunningLocationManager!

    // Timer for updating the UI every second
    var updateTimer: Timer?
    var isSwipeEnabled = true
    var elapsedSeconds: Int = 0
    var isPaused: Bool = false // Track if the workout is paused
    var lastLocation: CLLocation?
    var isFirstLocationAfterResume: Bool = false // Flag to handle location updates after resuming

    // MARK: - Constants
    enum LayoutConstants {
        static let controlButtonsBottomPadding: CGFloat = 50
        static let circleIndicatorsTopPadding: CGFloat = 15
        static let mapStatsViewHeight: CGFloat = 220
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupLocationManager()
        setupGestureRecognizers()
        setupButtonActions()

        // Set background color based on current interface style
        updateBackgroundColor()

        // Initialize circle indicators for two views (Timer and Map)
        circleIndicatorsView.numberOfIndicators = 2
        updatePageIndicators(activeIndex: 0) // Start with the timer view as active

        // Start the countdown when the view loads
        startInitialCountdown()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePageIndicators(activeIndex: timerStatsView.alpha == 1 ? 0 : 1)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
        locationManager.stopTracking()
    }

    // MARK: - Setup Methods
    func setupViews() {
        timerStatsView = RunTimerStatsView()
        timerStatsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerStatsView)

        mapViewContainer = MapTrackingView()
        mapViewContainer.translatesAutoresizingMaskIntoConstraints = false
        mapViewContainer.alpha = 0 // Initially hidden
        view.addSubview(mapViewContainer)

        mapStatsView = RunMapStatsView()
        mapStatsView.translatesAutoresizingMaskIntoConstraints = false
        mapViewContainer.addSubview(mapStatsView)

        controlButtonsView = ControlButtonsView()
        controlButtonsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlButtonsView)

        circleIndicatorsView = CircleIndicatorsView()
        circleIndicatorsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circleIndicatorsView)

        setupConstraints()
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            timerStatsView.topAnchor.constraint(equalTo: view.topAnchor),
            timerStatsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerStatsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timerStatsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            mapViewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            mapViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            mapStatsView.leadingAnchor.constraint(equalTo: mapViewContainer.leadingAnchor),
            mapStatsView.trailingAnchor.constraint(equalTo: mapViewContainer.trailingAnchor),
            mapStatsView.bottomAnchor.constraint(equalTo: mapViewContainer.bottomAnchor),
            mapStatsView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.26),

            controlButtonsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -LayoutConstants.controlButtonsBottomPadding),
            controlButtonsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlButtonsView.widthAnchor.constraint(equalTo: view.widthAnchor),
            controlButtonsView.heightAnchor.constraint(equalToConstant: 50),

            circleIndicatorsView.topAnchor.constraint(equalTo: controlButtonsView.bottomAnchor, constant: LayoutConstants.circleIndicatorsTopPadding),
            circleIndicatorsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleIndicatorsView.widthAnchor.constraint(equalToConstant: 50),
            circleIndicatorsView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func setupLocationManager() {
        runSessionModel = RunSessionModel()
        locationManager = RunningLocationManager()
        locationManager.delegate = self
    }

    func setupGestureRecognizers() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    func setupButtonActions() {
        controlButtonsView.stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        controlButtonsView.finishButton.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        controlButtonsView.continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    }

    // MARK: - Gesture Handling
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard isSwipeEnabled else { return }
        if gesture.direction == .left {
            switchToMapView()
        } else if gesture.direction == .right {
            switchToTimerView()
        }
    }

    func switchToMapView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.timerStatsView.alpha = 0
            self.mapViewContainer.alpha = 1
        }) { _ in
            self.updateAllStatistics()
            self.updatePageIndicators(activeIndex: 1) // Map view is active
        }
    }

    func switchToTimerView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.timerStatsView.alpha = 1
            self.mapViewContainer.alpha = 0
        }) { _ in
            self.updateAllStatistics()
            self.updatePageIndicators(activeIndex: 0) // Timer view is active
        }
    }

    // MARK: - UI Updates
    func updatePageIndicators(activeIndex: Int) {
        circleIndicatorsView.updatePageIndicators(activeIndex: activeIndex)
    }

    func updateAllStatistics() {
        mapStatsView.displayStats(runSessionModel)
        timerStatsView.displayStats(runSessionModel)
    }

    func updateBackgroundColor() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
    }

    func updateLabelColors() {
        let color = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        timerStatsView.updateLabelColors(color)
        mapStatsView.updateLabelColors(color)
    }

    func updateMapStatsViewBackground() {
        mapStatsView.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
    }

    // MARK: - Button Actions
    @objc func stopButtonTapped() {
        controlButtonsView.showFinishAndContinueButtons()

        if timerStatsView.isCountdownRunning {
            timerStatsView.stopCountdown()
            showCircleIndicatorsView()
            enableSwipeGestures(true)
        } else {
            updateTimer?.invalidate()
            timerStatsView.showPausedStatus()
            locationManager.stopTracking() // Stop location tracking when paused
            isPaused = true // Mark workout as paused
        }
    }

    @objc func finishButtonTapped() {
        // Stop the workout
        updateTimer?.invalidate()
        locationManager.stopTracking()
        isPaused = true

        // Perform the segue to the next screen
        performSegue(withIdentifier: "FreeRunFinishedSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FreeRunFinishedSegue",
           let destinationVC = segue.destination as? RunFinishedViewController { // Update to WorkOutFinishedViewController
            // Pass workout data
            destinationVC.runSessionModel = runSessionModel
            destinationVC.segments = mapViewContainer.getSegments() // Pass coordinates
        }
    }

    @objc func continueButtonTapped() {
        controlButtonsView.showStopButton()

        if timerStatsView.alpha == 0 {
            switchToTimerView()
        }

        hideCircleIndicatorsView()   // Hide indicators when countdown starts
        enableSwipeGestures(false)   // Disable swipe gestures during countdown

        startCountdown()
    }

    func startInitialCountdown() {
        hideCircleIndicatorsView()
        enableSwipeGestures(false)

        timerStatsView.startCountdown { [weak self] in
            self?.showCircleIndicatorsView()
            self?.enableSwipeGestures(true)
            self?.startWorkout()
        }
    }

    func startCountdown() {
        timerStatsView.startCountdown { [weak self] in
            self?.showCircleIndicatorsView()
            self?.enableSwipeGestures(true)
            self?.startWorkout()
        }
    }

    // MARK: - Workout Control
    func startWorkout() {
        enableSwipeGestures(true)
        isFirstLocationAfterResume = true // Indicate that the next location update is after resuming
        mapViewContainer.startNewSegment() // Start a new segment in the map view
        locationManager.startTracking()
        startUpdateTimer()
        isPaused = false // Mark workout as not paused
    }

    func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    @objc func updateStats() {
        elapsedSeconds += 1
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        runSessionModel.updateTime(hours: hours, minutes: minutes, seconds: seconds)
        updateAllStatistics()
        runSessionModel.resetChangeFlag()
    }

    func hideCircleIndicatorsView() {
        circleIndicatorsView.isHidden = true
    }

    func showCircleIndicatorsView() {
        circleIndicatorsView.isHidden = false
    }

    func enableSwipeGestures(_ enable: Bool) {
        isSwipeEnabled = enable
        view.gestureRecognizers?.forEach { $0.isEnabled = enable }
    }

    // MARK: - Trait Collection Changes
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBackgroundColor()
        updateLabelColors()
        updateMapStatsViewBackground()
        updatePageIndicators(activeIndex: timerStatsView.alpha == 1 ? 0 : 1)
    }
}

// MARK: - Location Manager Delegate
extension FreeRunViewController: LocationManagerDelegate {
    func locationManager(_ manager: RunningLocationManager, didUpdateLocation location: CLLocation) {
        if isFirstLocationAfterResume {
            lastLocation = location
            isFirstLocationAfterResume = false
            return
        }

        runSessionModel.updateLocation(location: location, lastLocation: lastLocation)
        lastLocation = location
        mapViewContainer.updateLocation(coordinate: location.coordinate)
        updateAllStatistics()
    }

    func locationManager(_ manager: RunningLocationManager, didUpdateElevationGain elevationGain: Double) {
        runSessionModel.updateElevationGain(elevationGain)
        updateAllStatistics()
    }

    func locationManager(_ manager: RunningLocationManager, didFailWithError error: Error) {
        let alert = UIAlertController(title: "Location Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
