//
//  HikeWalkViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 25/1/2025.
//

import UIKit
import CoreLocation

class HikeWalkViewController: UIViewController {

    // MARK: - UI Components
    private var hikeTimerStatsView: HikeTimerStatsView!
    private var mapViewContainer: MapTrackingView!
    private var hikeMapStatsView: HikeMapStatsView!
    private var controlButtonsView: ControlButtonsView!
    private var circleIndicatorsView: CircleIndicatorsView!
    private var compassView: CompassView!

    // MARK: - Properties
    private var hikeSessionModel: HikeSessionModel!
    private var locationManager: HikingLocationManager!
    private var compassManager: CompassManager!

    private var updateTimer: Timer?
    private var elapsedSeconds: Int = 0
    private var isSwipeEnabled: Bool = true
    private var currentViewIndex: Int = 0
    private var isPaused: Bool = false
    private var isCountdownRunning: Bool = false
    private var lastLocation: CLLocation?

    // MARK: - Constants
    enum LayoutConstants {
        static let controlButtonsBottomPadding: CGFloat = 50
        static let circleIndicatorsTopPadding: CGFloat = 15
        static let mapStatsViewHeight: CGFloat = 220
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupManagers()
        setupGestureRecognizers()
        setupButtonActions()
        updateBackgroundColor()

        circleIndicatorsView.numberOfIndicators = 3
        updatePageIndicators(activeIndex: currentViewIndex)
        startInitialCountdown()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
        locationManager.stopTracking()
        compassManager.stopTracking()
    }

    // MARK: - Setup Methods
    private func setupViews() {
        hikeTimerStatsView = HikeTimerStatsView()
        hikeTimerStatsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hikeTimerStatsView)

        mapViewContainer = MapTrackingView()
        mapViewContainer.translatesAutoresizingMaskIntoConstraints = false
        mapViewContainer.alpha = 0
        view.addSubview(mapViewContainer)

        hikeMapStatsView = HikeMapStatsView()
        hikeMapStatsView.translatesAutoresizingMaskIntoConstraints = false
        mapViewContainer.addSubview(hikeMapStatsView)

        controlButtonsView = ControlButtonsView()
        controlButtonsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlButtonsView)

        circleIndicatorsView = CircleIndicatorsView()
        circleIndicatorsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circleIndicatorsView)

        compassView = CompassView()
        compassView.translatesAutoresizingMaskIntoConstraints = false
        compassView.alpha = 0
        compassView.isUserInteractionEnabled = false
        view.addSubview(compassView)

        setupConstraints()
    }

    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hikeTimerStatsView.topAnchor.constraint(equalTo: view.topAnchor),
            hikeTimerStatsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hikeTimerStatsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hikeTimerStatsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            mapViewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            mapViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hikeMapStatsView.leadingAnchor.constraint(equalTo: mapViewContainer.leadingAnchor),
            hikeMapStatsView.trailingAnchor.constraint(equalTo: mapViewContainer.trailingAnchor),
            hikeMapStatsView.bottomAnchor.constraint(equalTo: mapViewContainer.bottomAnchor),
            hikeMapStatsView.heightAnchor.constraint(equalToConstant: LayoutConstants.mapStatsViewHeight),

            compassView.topAnchor.constraint(equalTo: view.topAnchor),
            compassView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            compassView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            compassView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

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

    private func setupManagers() {
        hikeSessionModel = HikeSessionModel()

        // Setup location manager
        locationManager = HikingLocationManager()
        locationManager.delegate = self

        // Setup compass manager
        compassManager = CompassManager()
        compassManager.delegate = self
        compassManager.startTracking() // Start heading and elevation tracking
    }

    private func setupGestureRecognizers() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    private func setupButtonActions() {
        controlButtonsView.stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        controlButtonsView.finishButton.addTarget(self, action: #selector(finishButtonTapped), for: .touchUpInside)
        controlButtonsView.continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    }

    // MARK: - Gesture Handling
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard isSwipeEnabled else { return }
        if gesture.direction == .left {
            if currentViewIndex < 2 {
                currentViewIndex += 1
                switchToView(at: currentViewIndex)
            }
        } else if gesture.direction == .right {
            if currentViewIndex > 0 {
                currentViewIndex -= 1
                switchToView(at: currentViewIndex)
            }
        }
    }

    private func switchToView(at index: Int) {
        UIView.animate(withDuration: 0.3) {
            self.hikeTimerStatsView.alpha = (index == 0) ? 1 : 0
            self.compassView.alpha = (index == 1) ? 1 : 0
            self.mapViewContainer.alpha = (index == 2) ? 1 : 0
        } completion: { _ in
            self.updateAllStatistics()
            self.updatePageIndicators(activeIndex: index)
        }
    }

    // MARK: - Button Actions
    @objc private func stopButtonTapped() {
        controlButtonsView.showFinishAndContinueButtons()
        // Update CompassView's status label to show "Paused"
        compassView.updateStatusLabel(paused: true)
        if isCountdownRunning {
            hikeTimerStatsView.stopCountdown()
            isCountdownRunning = false
            showCircleIndicatorsView()
            enableSwipeGestures(true)
        } else {
            updateTimer?.invalidate()
            hikeTimerStatsView.showPausedStatus()
            locationManager.stopTracking()
            isPaused = true
        }
    }

    @objc private func finishButtonTapped() {
        updateTimer?.invalidate()
        locationManager.stopTracking()
        compassManager.stopTracking()
        performSegue(withIdentifier: "HikeWalkFinishedSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HikeWalkFinishedSegue",
           let destinationVC = segue.destination as? HikeWalkFinishedViewController { // Update to WorkOutFinishedViewController
            // Pass workout data
            destinationVC.hikeSessionModel = hikeSessionModel
            destinationVC.segments = mapViewContainer.getSegments() // Pass coordinates
        }
    }

    @objc private func continueButtonTapped() {
        controlButtonsView.showStopButton()
        currentViewIndex = 0 // Always move to the leftmost screen for countdown
        switchToView(at: currentViewIndex)
        hideCircleIndicatorsView()
        enableSwipeGestures(false)
        isCountdownRunning = true

        hikeTimerStatsView.startCountdown { [weak self] in
            self?.isCountdownRunning = false
            self?.showCircleIndicatorsView()
            self?.enableSwipeGestures(true)
            self?.startWorkout()
            // Clear CompassView's status label when resuming
            self?.compassView.updateStatusLabel(paused: false)
        }
    }

    // MARK: - Workout Control
    private func startInitialCountdown() {
        currentViewIndex = 0 // Always move to the leftmost screen for countdown
        switchToView(at: currentViewIndex)
        hideCircleIndicatorsView()
        enableSwipeGestures(false)
        isCountdownRunning = true

        hikeTimerStatsView.startCountdown { [weak self] in
            self?.isCountdownRunning = false
            self?.showCircleIndicatorsView()
            self?.enableSwipeGestures(true)
            self?.startWorkout()
        }
    }

    private func startWorkout() {
        isPaused = false
        locationManager.startTracking()
        startUpdateTimer()
    }

    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            let hours = self.elapsedSeconds / 3600
            let minutes = (self.elapsedSeconds % 3600) / 60
            let seconds = self.elapsedSeconds % 60
            self.hikeSessionModel.updateTime(hours: hours, minutes: minutes, seconds: seconds)
            self.updateAllStatistics()
        }
    }

    private func updateAllStatistics() {
        hikeTimerStatsView.displayStats(hikeSessionModel)
        hikeMapStatsView.displayStats(hikeSessionModel)
    }

    private func updatePageIndicators(activeIndex: Int) {
        circleIndicatorsView.updatePageIndicators(activeIndex: activeIndex)
    }
    
    private func updateBackgroundColor() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
    }

    // MARK: - UI Updates
    private func updateUIForCurrentMode() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        view.backgroundColor = isDarkMode ? .black : .white
        hikeTimerStatsView.updateLabelColors(isDarkMode ? .white : .black)
        hikeTimerStatsView.updateStatusLabelColor(.systemOrange) 
        hikeMapStatsView.updateLabelColors(isDarkMode ? .white : .black)
        hikeMapStatsView.backgroundColor = isDarkMode ? .black : .white
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        updateUIForCurrentMode()
        compassView.updateLabelColors(for: isDarkMode)
        updateUIForCurrentMode()
    }
    
    private func hideCircleIndicatorsView() {
        circleIndicatorsView.isHidden = true
    }

    private func showCircleIndicatorsView() {
        circleIndicatorsView.isHidden = false
    }

    private func enableSwipeGestures(_ enable: Bool) {
        isSwipeEnabled = enable
        view.gestureRecognizers?.forEach { $0.isEnabled = enable }
    }
}

// MARK: - HikingLocationManagerDelegate
extension HikeWalkViewController: HikingLocationManagerDelegate {
    func locationManager(_ manager: HikingLocationManager, didUpdateLocation location: CLLocation) {
        hikeSessionModel.updateLocation(location: location, lastLocation: lastLocation)
        mapViewContainer.updateLocation(coordinate: location.coordinate)
        hikeSessionModel.updateElevation(currentElevation: location.altitude)
        updateAllStatistics()
        lastLocation = location
    }

    func locationManager(_ manager: HikingLocationManager, didUpdateElevationGain elevationGain: Double) {
        hikeSessionModel.updateElevationGain(elevationGain)
        updateAllStatistics()
    }

    func locationManager(_ manager: HikingLocationManager, didFailWithError error: Error) {
        let alert = UIAlertController(
            title: "Location Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
// MARK: - CompassManagerDelegate
extension HikeWalkViewController: CompassManagerDelegate {
    func compassManager(_ manager: CompassManager, didUpdateHeading heading: CLLocationDirection) {
        compassView.updateHeading(heading: heading)
    }

    func compassManager(_ manager: CompassManager, didUpdateCurrentElevation elevation: Double) {
        compassView.updateCurrentElevation(elevation: elevation)
    }

    func compassManager(_ manager: CompassManager, didFailWithError error: Error) {
        let alert = UIAlertController(
            title: "Compass Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}
