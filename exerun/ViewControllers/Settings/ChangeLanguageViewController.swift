//
//  ChangeLanguageViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/4/2025.
//


import UIKit

class ChangeLanguageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

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
        button.setTitle(NSLocalizedString("back_button", comment: "Back button"), for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        return button
    }()

    private let changeLanguageLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("change_language", comment: "Change language section title")
        label.font = UIFont(name: "Avenir-Medium", size: 22)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let tableView = UITableView()
    private let languages = [("English", "en"), ("Українська", "uk")]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(changeLanguageLabel)
        view.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            changeLanguageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            changeLanguageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: changeLanguageLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func handleBackButton() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - TableView DataSource & Delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (languageName, code) = languages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = languageName

        if code == LocalizationManager.shared.currentLanguage {
            cell.textLabel?.textColor = .systemOrange
            cell.accessoryType = .checkmark
            cell.tintColor = .systemOrange 
        } else {
            cell.textLabel?.textColor = .label
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLanguageCode = languages[indexPath.row].1
        LocalizationManager.shared.setLanguage(selectedLanguageCode)
        tableView.reloadData()
        showRestartAlert()
    }

    private func showRestartAlert() {
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("app_restart_notice", comment: "Notice to restart app after language change"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                window.rootViewController = vc
                window.makeKeyAndVisible()
            }
        })
        present(alert, animated: true)
    }
}
