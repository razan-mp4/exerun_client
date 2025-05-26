//
//  ContactUsViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/4/2025.
//

import UIKit

class ContactUsViewController: UIViewController {

    private let contactEmail = "exerun.support@gmail.com"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "exerun"
        label.font = UIFont(name: "Avenir", size: 32)
        label.textColor = .systemOrange
        label.textAlignment = .center
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

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("contact_message", comment: "Contact message above the email")
        label.font = UIFont(name: "Avenir", size: 18)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "exerun.support@gmail.com"
        label.font = UIFont(name: "Avenir-Medium", size: 20)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var copyButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "doc.on.doc")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .systemOrange
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(copyEmail), for: .touchUpInside)
        return button
    }()

    private let confirmationLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("copied_confirmation", comment: "Confirmation message after copying email")
        label.textColor = .systemOrange
        label.font = UIFont(name: "Avenir", size: 14)
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
    }

    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(messageLabel)
        view.addSubview(emailLabel)
        view.addSubview(copyButton)
        view.addSubview(confirmationLabel)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            emailLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            emailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            copyButton.centerYAnchor.constraint(equalTo: emailLabel.centerYAnchor),
            copyButton.leadingAnchor.constraint(equalTo: emailLabel.trailingAnchor, constant: 8),
            copyButton.widthAnchor.constraint(equalToConstant: 24),
            copyButton.heightAnchor.constraint(equalToConstant: 24),

            confirmationLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 10),
            confirmationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func handleBack() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func copyEmail() {
        UIPasteboard.general.string = contactEmail
        UIView.animate(withDuration: 0.3) {
            self.confirmationLabel.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.3) {
                self.confirmationLabel.alpha = 0
            }
        }
    }
}
