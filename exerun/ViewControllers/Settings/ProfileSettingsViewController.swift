//
//  ProfileSettingsViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/4/2025.
//

import UIKit

final class ProfileSettingsViewController: UIViewController {

    // MARK: - Properties
    private var isTransitioning = false
    private var currentStepIndex = 0
    private var profileInput: ProfileInput = ProfileInput()
    private var steps: [UIView] = []

    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "exerun"
        label.font = UIFont(name: "Avenir", size: 32)
        label.textAlignment = .center
        label.textColor = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("back_button", comment: ""), for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        return button
    }()

    private let containerView = UIView()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("save_changes_button", comment: ""), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemOrange
        button.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleSaveChanges), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadProfile()
        setupSteps()
        showStep(index: steps.count - 1)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCoreDataDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )

    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(containerView)
        view.addSubview(saveButton)

        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            containerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),

            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func loadProfile() {
        if let profile = ProfileStorage.shared.getProfile() {
            profileInput = ProfileInput(
                height: Int(profile.height),
                weight: Int(profile.weight),
                birthday: profile.birthday,
                gender: profile.gender
            )
        }
    }

    private func setupSteps() {
        steps = [
            HeightUpdateView(initialHeight: profileInput.height) { [weak self] height in
                self?.profileInput.height = height
            },
            WeightUpdateView(initialWeight: profileInput.weight) { [weak self] weight in
                self?.profileInput.weight = weight
            },
            BirthdayUpdateView(initialBirthday: profileInput.birthday) { [weak self] birthday in
                self?.profileInput.birthday = birthday
            },
            GenderUpdateView(initialGender: profileInput.gender) { [weak self] gender in
                self?.profileInput.gender = gender
            },
            AllProfileSettingsView(profile: profileInput, onEdit: { [weak self] stepIndex in
                self?.showStep(index: stepIndex)
            })
        ]
    }

    private func showStep(index: Int) {
        guard !isTransitioning else { return }
        isTransitioning = true

        let oldStep = containerView.subviews.first
        let newStep = steps[index]

      
        currentStepIndex = index
        newStep.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(newStep)

        NSLayoutConstraint.activate([
            newStep.topAnchor.constraint(equalTo: containerView.topAnchor),
            newStep.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newStep.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newStep.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        newStep.alpha = 0
        newStep.transform = CGAffineTransform(translationX: 30, y: 0)

        UIView.animate(withDuration: 0.3, animations: {
            newStep.alpha = 1
            newStep.transform = .identity
            oldStep?.alpha = 0
            oldStep?.transform = CGAffineTransform(translationX: -30, y: 0)
        }, completion: { _ in
            oldStep?.removeFromSuperview()
            self.isTransitioning = false
        })

        // ✅ Save button visibility logic
        saveButton.isHidden = (newStep is AllProfileSettingsView)
    }


    @objc private func handleSaveChanges() {
        guard profileInput.isComplete else { return }

        // 1️⃣  Save locally (marks entity dirty + kicks sync)
        ProfileStorage.shared.updateProfile(with: profileInput)

        // 2️⃣  Refresh UI (no server call)
        loadProfile()
        setupSteps()
        showStep(index: steps.count - 1)
    }

    @objc private func handleBackButton() {
        if currentStepIndex == steps.count - 1 {
            dismiss(animated: true)
        } else {
            showStep(index: steps.count - 1)
            loadProfile()
        }
    }
    @objc private func handleCoreDataDidSave() {
        print("🔄 Core Data saved — refreshing profileInput and review step")
        loadProfile()
        
        // If we are on the review screen, update it immediately
        if let reviewView = containerView.subviews.first as? AllProfileSettingsView {
            reviewView.updateView(profile: profileInput)
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
