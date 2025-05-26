//
//  StatsViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/1/2024.
//

import UIKit

final class StatsViewController: UIViewController, RobotHelpProvider {

    // MARK: – UI
    //------------------------------------------------------------
    private var robotHeightConstraint: NSLayoutConstraint!

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = .systemOrange
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "exerun"
        lbl.font = UIFont(name: "Avenir", size: 32)
        lbl.textColor = .systemOrange
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let settingsButton: UIButton = {
        let b = UIButton(type: .system)
        let img = UIImage(named: "settings_icon") ?? UIImage(systemName: "gearshape")
        b.setImage(img, for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let statsLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = NSLocalizedString("statistics_title", comment: "")
        lbl.font = UIFont(name: "Avenir-Heavy", size: 33)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let historyButton: UIButton = {
        let b = UIButton(type: .system)
        let img = UIImage(named: "history_icon") ?? UIImage(systemName: "clock")
        b.setImage(img, for: .normal)
        b.setTitle("All Workouts", for: .normal)
        b.tintColor = .systemOrange
        b.setTitleColor(.systemOrange, for: .normal)
        b.titleLabel?.font = UIFont(name: "Avenir", size: 16)
        b.semanticContentAttribute = .forceRightToLeft
        b.contentHorizontalAlignment = .right
        return b
    }()

    private let syncedLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont(name: "Avenir", size: 14)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let statsDiagramView = StatsDiagramView()

    private let robotContainer = UIView()
    private var robotView: RobotView { RobotEnvironment.sharedRobotView }

    // MARK: – Lifecycle
    //------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        robotView.configure(file: "robot.usdc")
        view.backgroundColor = .systemBackground

        setupHeader()
        attachRobotView()
        setupStatsSection()

        historyButton.addTarget(self, action: #selector(openHistory),  for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)


        updateSyncStatus()
        robotView.helpProvider = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statsLabel.alpha = 1
        separator.alpha  = 1
        attachRobotView()
        robotView.helpProvider = self
        // 🔔 Listen for sync-state flips coming from both managers
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSyncStateChanged),
                                               name: .syncStateChanged,
                                               object: nil)
        
        updateSyncStatus()
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 0.25) {
            self.statsLabel.alpha = 0
            self.separator.alpha  = 0
        }
        robotView.stopSpeaking()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: – Layout helpers
    //------------------------------------------------------------
    private func setupHeader() {
        view.addSubview(titleLabel)
        view.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            settingsButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 28),
            settingsButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        updateSetButColor(for: traitCollection)
    }

    private func attachRobotView() {
        robotContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(robotContainer)

        NSLayoutConstraint.activate([
            robotContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            robotContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            robotContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])

        robotView.removeFromSuperview()
        robotView.translatesAutoresizingMaskIntoConstraints = false
        robotContainer.addSubview(robotView)

        NSLayoutConstraint.activate([
            robotView.topAnchor.constraint(equalTo: robotContainer.topAnchor),
            robotView.leadingAnchor.constraint(equalTo: robotContainer.leadingAnchor),
            robotView.trailingAnchor.constraint(equalTo: robotContainer.trailingAnchor),
            robotView.bottomAnchor.constraint(equalTo: robotContainer.bottomAnchor),
            robotView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    private func setupStatsSection() {
        [separator, statsLabel, historyButton, syncedLabel, statsDiagramView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: robotContainer.bottomAnchor, constant: 8),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            separator.heightAnchor.constraint(equalToConstant: 1),

            statsLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            statsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            historyButton.centerYAnchor.constraint(equalTo: statsLabel.centerYAnchor),
            historyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            syncedLabel.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 8),
            syncedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            statsDiagramView.topAnchor.constraint(equalTo: syncedLabel.bottomAnchor, constant: -25),
            statsDiagramView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsDiagramView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // MARK: – Sync status
    //------------------------------------------------------------
    @objc private func handleSyncStateChanged() { updateSyncStatus() }

    private func updateSyncStatus() {

        let dirtyAccount  = AccountSyncManager.shared.hasUnsyncedAccount
        let dirtyWorkouts = WorkoutSyncManager.shared.hasUnsyncedWorkouts
        let dirtyPlans    = GymPlanSyncManager.shared.hasUnsyncedGymPlans

        let workoutPullDone = WorkoutSyncManager.shared.isPullComplete
        let gymPullDone     = GymPlanSyncManager.shared.isPullComplete

        let pullDone = workoutPullDone && gymPullDone


        if !pullDone {
            syncedLabel.text      = "Fetching…"
            syncedLabel.textColor = .systemOrange
            return
        }

        let allGood = !dirtyAccount && !dirtyWorkouts && !dirtyPlans
        syncedLabel.text      = allGood ? "Synced" : "Unsynced"
        syncedLabel.textColor = allGood ? .systemOrange : .secondaryLabel

    }

    // MARK: – Navigation
    //------------------------------------------------------------
    @objc private func openHistory() {
        performSegue(withIdentifier: "showWorkoutHistorySegue", sender: self)
    }

    @objc private func openSettings() {
        performSegue(withIdentifier: "showSettingsFromStats", sender: self)
    }

    // MARK: – Misc
    //------------------------------------------------------------
    private func updateSetButColor(for trait: UITraitCollection) {
        settingsButton.tintColor = trait.userInterfaceStyle == .dark ? .white : .black
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateSetButColor(for: traitCollection)
    }

    // MARK: – RobotHelpProvider
    //------------------------------------------------------------
    func robotHelpScript() -> [String] {
        [
            NSLocalizedString("stats_help_1", comment: ""),
            NSLocalizedString("stats_help_2", comment: "")
        ]
    }
}
