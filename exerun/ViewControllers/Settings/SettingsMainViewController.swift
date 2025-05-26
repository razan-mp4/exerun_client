//
//  SettingsMainViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/4/2025.
//

import UIKit

class SettingsMainViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("back_button", comment: "Back button title"), for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 40   // 80/2 = perfect circle
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        // Add a swap/change icon inside the overlay
        let icon = UIImageView(image: UIImage(systemName: "arrow.triangle.2.circlepath"))
        icon.tintColor = .white
        icon.alpha = 0.8
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])

        return view
    }()


    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Name Surname"
        label.font = UIFont(name: "Avenir-Medium", size: 22)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let versionLabel: UILabel = {
        let label = UILabel()
        label.text = "exerun v1.0.0"
        label.font = UIFont(name: "Avenir-Light", size: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let settingsTableView = UITableView()

    private let settingsOptions = [
        NSLocalizedString("account_settings", comment: ""),
        NSLocalizedString("profile_settings", comment: ""),
        NSLocalizedString("change_language", comment: ""),
        // NSLocalizedString("units_of_measurement", comment: ""),
        NSLocalizedString("contact_us", comment: "")
    ]

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupConstraints()
        loadUserData()
        NotificationCenter.default.addObserver(self, selector: #selector(handleCoreDataDidSave), name: .NSManagedObjectContextDidSave, object: nil)
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(backButton)
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(settingsTableView)
        view.addSubview(versionLabel)

        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.translatesAutoresizingMaskIntoConstraints = false
        settingsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changeProfilePicture))
        profileImageView.addGestureRecognizer(tapGesture)
        
        profileImageView.addSubview(overlayView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            profileImageView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
           
            overlayView.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            settingsTableView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            settingsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsTableView.bottomAnchor.constraint(equalTo: versionLabel.topAnchor, constant: -4),
            
            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func handleBack() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func changeProfilePicture() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func handleCoreDataDidSave() {
        print("🔄 Core Data saved, reloading user data")
        loadUserData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: - UITableViewDelegate and UITableViewDataSource

extension SettingsMainViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.textLabel?.text = settingsOptions[indexPath.row]
        cell.textLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Perform Segue based on selected row
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "showAccountSettings", sender: nil)
        case 1:
            performSegue(withIdentifier: "showProfileSettings", sender: nil)
        case 2:
            performSegue(withIdentifier: "showChangeLanguage", sender: nil)
        case 3:
            performSegue(withIdentifier: "showContactUs", sender: nil)
        default:
            break
        }
    }

    
    private func loadUserData() {
        if let user = UserStorage.shared.getUser() {
            nameLabel.text = "\(user.name) \(user.surname)"

            if let profile = ProfileStorage.shared.getProfile() {
                if let imageData = profile.imageData,
                   let image = UIImage(data: imageData) {
                    profileImageView.image = image
                    overlayView.isHidden = false
                } else {
                    // No image → show plus sign
                    profileImageView.image = UIImage(systemName: "plus.circle")
                    profileImageView.tintColor = .systemGray
                    overlayView.isHidden = true
                }
            }
        }
    }

}

extension SettingsMainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {

            self.profileImageView.image = image
            self.overlayView.isHidden = false

            ProfileStorage.shared.saveProfileImage(imageData)

            ExerunServerAPIManager.shared.uploadProfileImage(imageData) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url):
                        ProfileStorage.shared.updateProfilePictureURL(url)
                    case .failure(let error):
                        print("❌ Failed uploading image:", error)
                    }
                }
            }
        }
    }
}
