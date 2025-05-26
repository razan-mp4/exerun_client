//
//  AccountSettingsViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/4/2025.
//

import UIKit
import CoreData

final class AccountSettingsViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    private let nameField = UITextField()
    private let surnameField = UITextField()

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
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("save_changes_button", comment: ""), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemOrange
        button.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("logout_button", comment: ""), for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadUserData()
        saveButton.addTarget(self, action: #selector(handleSaveChanges), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCoreDataDidSave), name: .NSManagedObjectContextDidSave, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(saveButton)
        view.addSubview(logoutButton)

        nameField.delegate = self
        surnameField.delegate = self

        nameField.placeholder = NSLocalizedString("name_placeholder", comment: "")
        surnameField.placeholder = NSLocalizedString("surname_placeholder", comment: "")
        [nameField, surnameField].forEach {
            $0.borderStyle = .roundedRect
            $0.font = UIFont(name: "Avenir", size: 18)
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            nameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            nameField.heightAnchor.constraint(equalToConstant: 44),

            surnameField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 20),
            surnameField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            surnameField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            surnameField.heightAnchor.constraint(equalToConstant: 44),

            saveButton.topAnchor.constraint(equalTo: surnameField.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            saveButton.heightAnchor.constraint(equalToConstant: 50),

            logoutButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 30),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Data
    private func loadUserData() {
        if let user = UserStorage.shared.getUser() {
            nameField.text = user.name
            surnameField.text = user.surname
        }
    }

    // MARK: - Actions
    @objc private func handleBack() {
        dismiss(animated: true)
    }

    @objc private func handleSaveChanges() {
        let name    = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let surname = surnameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty, !surname.isEmpty else { return }

        // 1️⃣  Save locally (dirty + sync)
        if let user = UserStorage.shared.getUser() {
            user.name    = name
            user.surname = surname
            UserStorage.shared.save(entity: user)   // sets isDirty + kicks sync
        }

        // 2️⃣  Close screen
        dismiss(animated: true)
    }

    @objc private func handleLogout() {
        // 1. Stop Sync
        WorkoutSyncManager.shared.suspend()
        
        // 2. Delete token
        KeychainManager.shared.deleteToken()

        // 3. Clear Core-Data
        DatabaseManager.shared.clearAllData()

        // 4. Reset sync flags
        WorkoutSyncManager.shared.resetPullState()

        // 5. Revert localisation to system default
        LocalizationManager.shared.resetToSystemLanguage()

        // 6. Show Auth storyboard
        switchToAuthStoryboard()
    }

    private func switchToAuthStoryboard() {
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else {
            print("❌ Could not find SceneDelegate")
            return
        }

        let storyboard = UIStoryboard(name: "Auth", bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() else {
            print("❌ Could not instantiate initial VC from Auth storyboard")
            return
        }

        sceneDelegate.window?.rootViewController = initialVC
        sceneDelegate.window?.makeKeyAndVisible()
    }

    
    @objc private func handleCoreDataDidSave() {
        print("🔄 Core Data saved, reloading user fields")
        loadUserData() // <-- this reloads name and surname into text fields
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

