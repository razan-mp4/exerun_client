//
//  SettingsViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/1/2024.
//

import UIKit

class FriendsViewController: UIViewController, RobotHelpProvider, UIScrollViewDelegate {

    private var separatorLine: UIView!
    private var friendsTitleLabel: UILabel!

    private var scrollView: UIScrollView!
    private var contentStackView: UIStackView!

    private let robotContainer = UIView()
    private var robotView: RobotView { RobotEnvironment.sharedRobotView }

    override func viewDidLoad() {
        super.viewDidLoad()

        robotView.configure(file: "robot.usdc")
        view.backgroundColor = .systemBackground

        setupHeader()
        attachRobotView()
        setupScrollView()

        robotView.helpProvider = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        attachRobotView()
        robotView.helpProvider = self 
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        robotView.stopSpeaking()
    }

    // MARK: - RobotHelpProvider
    func robotHelpScript() -> [String] {
        [
            NSLocalizedString("friends_help_1", comment: "Friends help 1"),
            NSLocalizedString("friends_help_2", comment: "Friends help 2")
        ]
    }

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
        let button = UIButton(type: .system)
        let image = UIImage(named: "settings_icon") ?? UIImage(systemName: "gearshape")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

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
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
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

    private func setupScrollView() {
        separatorLine = UIView()
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.backgroundColor = .systemOrange
        view.addSubview(separatorLine)

        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)

        friendsTitleLabel = UILabel()
        friendsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        friendsTitleLabel.text = NSLocalizedString("friends_title", comment: "Title for friends section")
        friendsTitleLabel.font = UIFont(name: "Avenir-Heavy", size: 33.0)
        friendsTitleLabel.textAlignment = .left
        scrollView.addSubview(friendsTitleLabel)

        contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 12
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: robotContainer.bottomAnchor, constant: 8),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            friendsTitleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: -3),
            friendsTitleLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 10),
            friendsTitleLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -10),
            friendsTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -20),

            contentStackView.topAnchor.constraint(equalTo: friendsTitleLabel.bottomAnchor, constant: 12),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    @objc private func openSettings() {
        performSegue(withIdentifier: "showSettingsFromFriends", sender: self)
    }

    private func updateSetButColor(for traitCollection: UITraitCollection) {
        settingsButton.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateSetButColor(for: traitCollection)
    }
}
