//
//  FreeCyclingViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//


import UIKit
import CoreLocation

class FreeCyclingViewController: UIViewController {

    // MARK: - UI Components
    var timerStatsView: CyclingTimerStatsView!
    var mapViewContainer: MapTrackingView!
    var mapStatsView: CyclingMapStatsView!
    var controlButtonsView: ControlButtonsView!
    var circleIndicatorsView: CircleIndicatorsView!

    var cyclingSessionModel: CyclingSessionModel!
    var locationManager: CyclingLocationManager!

    var updateTimer: Timer?
    var isSwipeEnabled = true
    var elapsedSeconds: Int = 0
    var isPaused: Bool = false
    var lastLocation: CLLocation?
    var isFirstLocationAfterResume = false

    enum LayoutConstants {
        static let controlButtonsBottomPadding: CGFloat = 50
        static let circleIndicatorsTopPadding: CGFloat = 15
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupLocationManager()
        setupGestureRecognizers()
        setupButtonActions()

        updateBackgroundColor()
        circleIndicatorsView.numberOfIndicators = 2
        updatePageIndicators(activeIndex: 0)
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

    func setupViews() {
        timerStatsView = CyclingTimerStatsView()
        timerStatsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerStatsView)

        mapViewContainer = MapTrackingView()
        mapViewContainer.translatesAutoresizingMaskIntoConstraints = false
        mapViewContainer.alpha = 0
        view.addSubview(mapViewContainer)

        mapStatsView = CyclingMapStatsView()
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
        cyclingSessionModel = CyclingSessionModel()
        locationManager = CyclingLocationManager()
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

    // MARK: - Gesture Actions
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard isSwipeEnabled else { return }
        if gesture.direction == .left {
            switchToMapView()
        } else if gesture.direction == .right {
            switchToTimerView()
        }
    }

    func switchToMapView() {
        UIView.animate(withDuration: 0.3) {
            self.timerStatsView.alpha = 0
            self.mapViewContainer.alpha = 1
        } completion: { _ in
            self.updateAllStatistics()
            self.updatePageIndicators(activeIndex: 1)
        }
    }

    func switchToTimerView() {
        UIView.animate(withDuration: 0.3) {
            self.timerStatsView.alpha = 1
            self.mapViewContainer.alpha = 0
        } completion: { _ in
            self.updateAllStatistics()
            self.updatePageIndicators(activeIndex: 0)
        }
    }

    func updateAllStatistics() {
        mapStatsView.displayStats(cyclingSessionModel)
        timerStatsView.displayStats(cyclingSessionModel)
    }

    func updatePageIndicators(activeIndex: Int) {
        circleIndicatorsView.updatePageIndicators(activeIndex: activeIndex)
    }

    func updateBackgroundColor() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
    }

    func startInitialCountdown() {
        hideCircleIndicatorsView()
        enableSwipeGestures(false)
        timerStatsView.startCountdown { [weak self] in
            self?.startWorkout()
            self?.showCircleIndicatorsView()
            self?.enableSwipeGestures(true)
        }
    }

    @objc func stopButtonTapped() {
        controlButtonsView.showFinishAndContinueButtons()

        if timerStatsView.isCountdownRunning {
            timerStatsView.stopCountdown()
            showCircleIndicatorsView()
            enableSwipeGestures(true)
        } else {
            updateTimer?.invalidate()
            timerStatsView.showPausedStatus()
            locationManager.stopTracking()
            isPaused = true
        }
    }

    @objc func finishButtonTapped() {
        updateTimer?.invalidate()
        locationManager.stopTracking()
        isPaused = true

        performSegue(withIdentifier: "FreeCyclingFinishedSegue", sender: self)
    }

    @objc func continueButtonTapped() {
        controlButtonsView.showStopButton()
        if timerStatsView.alpha == 0 { switchToTimerView() }

        hideCircleIndicatorsView()
        enableSwipeGestures(false)

        timerStatsView.startCountdown { [weak self] in
            self?.startWorkout()
            self?.showCircleIndicatorsView()
            self?.enableSwipeGestures(true)
        }
    }

    func startWorkout() {
        mapViewContainer.startNewSegment()
        isFirstLocationAfterResume = true
        locationManager.startTracking()
        startUpdateTimer()
        isPaused = false
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
        cyclingSessionModel.updateTime(hours: hours, minutes: minutes, seconds: seconds)
        updateAllStatistics()
        cyclingSessionModel.resetChangeFlag()
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

    // MARK: - Trait Changes
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBackgroundColor()
        updatePageIndicators(activeIndex: timerStatsView.alpha == 1 ? 0 : 1)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FreeCyclingFinishedSegue",
           let destinationVC = segue.destination as? CyclingFinishedViewController {
            destinationVC.cyclingSessionModel = cyclingSessionModel
            destinationVC.segments = mapViewContainer.getSegments()
        }
    }
}

// MARK: - LocationManagerDelegate
extension FreeCyclingViewController: CyclingLocationManagerDelegate {
    func locationManager(_ manager: CyclingLocationManager, didUpdateLocation location: CLLocation) {
        if isFirstLocationAfterResume {
            lastLocation = location
            isFirstLocationAfterResume = false
            return
        }

        cyclingSessionModel.updateLocation(location: location, lastLocation: lastLocation)
        lastLocation = location
        mapViewContainer.updateLocation(coordinate: location.coordinate)
        updateAllStatistics()
    }

    func locationManager(_ manager: CyclingLocationManager, didUpdateElevationGain elevationGain: Double) {
        cyclingSessionModel.updateElevationGain(elevationGain)
        updateAllStatistics()
    }

    func locationManager(_ manager: CyclingLocationManager, didFailWithError error: Error) {
        let alert = UIAlertController(title: "Location Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
