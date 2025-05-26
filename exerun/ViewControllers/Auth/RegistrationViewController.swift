//
//  RegistrationViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 16/4/2025.
//

import UIKit
import GoogleSignIn

final class RegistrationViewController: UIViewController, UITextFieldDelegate {

    // MARK: – UI ELEMENTS
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "exerun"
        label.font = UIFont(name: "Avenir", size: 32)
        label.textColor = .systemOrange
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nameTextField = RegistrationViewController.makeField(
        placeholder: NSLocalizedString("placeholder_first_name", comment: "First name")
    )
    private let surnameTextField = RegistrationViewController.makeField(
        placeholder: NSLocalizedString("placeholder_last_name", comment: "Last name")
    )
    private let emailTextField = RegistrationViewController.makeField(
        placeholder: NSLocalizedString("placeholder_email", comment: "Email"),
        keyboard: .emailAddress
    )
    private let passwordTextField = RegistrationViewController.makeSecureField(
        placeholder: NSLocalizedString("placeholder_password", comment: "Password")
    )
    private let repeatPasswordTextField = RegistrationViewController.makeSecureField(
        placeholder: NSLocalizedString("placeholder_repeat_password", comment: "Repeat password")
    )

    private lazy var googleButton = makeAuthButton(title: NSLocalizedString("button_google_signup", comment: "Sign up with Google"))

    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("button_sign_up", comment: "Sign up button"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemOrange
        button.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("button_back", comment: "Back button"), for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    // Error labels
    private let emailErrorLabel = RegistrationViewController.makeErrorLabel()
    private let passwordErrorLabel = RegistrationViewController.makeErrorLabel()
    private let repeatPwErrorLabel = RegistrationViewController.makeErrorLabel()

    // MARK: – CONSTRAINTS
    private var titleTopConstraint:     NSLayoutConstraint!
    private var titleCenterConstraint:  NSLayoutConstraint!
    private var signUpBottomConstraint: NSLayoutConstraint!

    // MARK: – Life‑cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        addSubviews()
        setupConstraints()
        assignDelegates()
        addTargets()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                         action: #selector(endEditing)))
    }

    private func addSubviews() {
        [
            titleLabel,
            nameTextField, surnameTextField,
            emailTextField, emailErrorLabel,
            passwordTextField, passwordErrorLabel,
            repeatPasswordTextField, repeatPwErrorLabel,
            googleButton,
            signUpButton,
            backButton
        ].forEach { view.addSubview($0) }
    }

    private func assignDelegates() {
        [
            nameTextField,
            surnameTextField,
            emailTextField,
            passwordTextField,
            repeatPasswordTextField
        ].forEach { $0.delegate = self }
    }

    private func addTargets() {
        signUpButton.addTarget(self,  action: #selector(handleEmailSignUp),  for: .touchUpInside)
        googleButton.addTarget(self,  action: #selector(handleGoogleSignUp), for: .touchUpInside)
    }

    @objc private func endEditing() { view.endEditing(true) }

    // MARK: – Layout
    private func setupConstraints() {
        let pad: CGFloat = 40

        titleTopConstraint    = titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                                constant: 10)
        titleCenterConstraint = titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)

        titleTopConstraint.isActive = true

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),

            nameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 35),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            nameTextField.heightAnchor.constraint(equalToConstant: 45),

            surnameTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 14),
            surnameTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            surnameTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            surnameTextField.heightAnchor.constraint(equalTo: nameTextField.heightAnchor),

            emailTextField.topAnchor.constraint(equalTo: surnameTextField.bottomAnchor, constant: 20),
            emailTextField.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            emailTextField.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            emailTextField.heightAnchor.constraint(equalTo: nameTextField.heightAnchor),

            emailErrorLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 4),
            emailErrorLabel.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            emailErrorLabel.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),

            passwordTextField.topAnchor.constraint(equalTo: emailErrorLabel.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalTo: nameTextField.heightAnchor),

            passwordErrorLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 4),
            passwordErrorLabel.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
            passwordErrorLabel.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),

            repeatPasswordTextField.topAnchor.constraint(equalTo: passwordErrorLabel.bottomAnchor, constant: 16),
            repeatPasswordTextField.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
            repeatPasswordTextField.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),
            repeatPasswordTextField.heightAnchor.constraint(equalTo: nameTextField.heightAnchor),

            repeatPwErrorLabel.topAnchor.constraint(equalTo: repeatPasswordTextField.bottomAnchor, constant: 4),
            repeatPwErrorLabel.leadingAnchor.constraint(equalTo: repeatPasswordTextField.leadingAnchor),
            repeatPwErrorLabel.trailingAnchor.constraint(equalTo: repeatPasswordTextField.trailingAnchor),

            googleButton.topAnchor.constraint(equalTo: repeatPwErrorLabel.bottomAnchor, constant: 32),
            googleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleButton.widthAnchor.constraint(equalTo: nameTextField.widthAnchor),
            googleButton.heightAnchor.constraint(equalToConstant: 40),

            signUpButton.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),
            signUpButton.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor),
            signUpButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        signUpBottomConstraint = signUpButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                                      constant: -40)
        signUpBottomConstraint.isActive = true

        [
            nameTextField,
            surnameTextField,
            emailTextField,
            passwordTextField,
            repeatPasswordTextField
        ].forEach { $0.setLeftPaddingPoints(8) }
    }

    // MARK: – Email / Password sign‑up
    @objc private func handleEmailSignUp() {
        let name = nameTextField.text      ?? ""
        let surname = surnameTextField.text   ?? ""
        let email = emailTextField.text     ?? ""
        let pw = passwordTextField.text  ?? ""
        let repeatPw  = repeatPasswordTextField.text ?? ""

        let validEmail = validateEmail(email)
        let validPw = validatePassword(pw)
        let pwMatch = validateRepeatPassword(pw, repeatPw)
        let namesOk = !name.trimmingCharacters(in: .whitespaces).isEmpty &&
                          !surname.trimmingCharacters(in: .whitespaces).isEmpty

        guard validEmail, validPw, pwMatch, namesOk else { return }

        setLoading(true, on: signUpButton)

        ExerunServerAPIManager.shared.register(email: email,
                                   password: pw,
                                   name: name,
                                   surname: surname) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                ExerunServerAPIManager.shared.getCurrentUser { userResult in
                    DispatchQueue.main.async {
                        self.setLoading(false, on: self.signUpButton)

                        switch userResult {
                        case .success(let remoteUser):
                            UserStorage.shared.save(remoteUser)
                            WorkoutSyncManager.shared.suspend()
                            WorkoutSyncManager.shared.resetPullState()
                            WorkoutSyncManager.shared.pull {
                                WorkoutSyncManager.shared.resume()        // ← ensure syncing is re-enabled
                                WorkoutSyncManager.shared.kick()          // ← this will now work if isDirty
                            }
                            GymPlanSyncManager.shared.pull()
                            GymPlanSyncManager.shared.kick()
                            AccountSyncManager.shared.kick()
                            self.launchMainInterface()

                        case .failure(let err):
                            self.showGenericError()
                        }
                    }
                }


            case .failure:
                DispatchQueue.main.async {
                    self.setLoading(false, on: self.signUpButton)
                    self.showGenericError()
                }
            }
        }
    }


    // MARK: – Google sign‑up
    @objc private func handleGoogleSignUp() {
        guard let clientID = Bundle.main.infoDictionary?["GOOGLE_CLIENT_ID"] as? String else { return }

        setLoading(true, on: googleButton)

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user, _ in
            guard let self = self else { return }

            guard let idToken = user?.authentication.idToken else {
                DispatchQueue.main.async { self.setLoading(false, on: self.googleButton) }
                return
            }

            ExerunServerAPIManager.shared.oauthLogin(idToken: idToken, provider: "google") { result in
                switch result {
                case .success:
                    // ✅ Token saved – now fetch user data
                    ExerunServerAPIManager.shared.getCurrentUser { userResult in
                        DispatchQueue.main.async {
                            self.setLoading(false, on: self.googleButton)

                            switch userResult {
                            case .success(let remoteUser):
                                UserStorage.shared.save(remoteUser)
                                WorkoutSyncManager.shared.suspend()
                                WorkoutSyncManager.shared.resetPullState()
                                WorkoutSyncManager.shared.pull {
                                    WorkoutSyncManager.shared.resume()        // ← ensure syncing is re-enabled
                                    WorkoutSyncManager.shared.kick()          // ← this will now work if isDirty
                                }
                                GymPlanSyncManager.shared.pull()
                                GymPlanSyncManager.shared.kick()
                                AccountSyncManager.shared.kick()
                                self.launchMainInterface()
                            case .failure:
                                self.showGenericError()
                            }
                        }
                    }

                case .failure:
                    DispatchQueue.main.async {
                        self.setLoading(false, on: self.googleButton)
                        self.showGenericError()
                    }
                }
            }
        }
    }


    // MARK: – Validation helpers
    private func validateEmail(_ email: String) -> Bool {
        let pattern = "(?:[A-Z0-9a-z._%+-]+)@(?:[A-Za-z0-9-]+\\.)+[A-Za-z]{2,64}"
        let valid = NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
        updateField(emailTextField, emailErrorLabel, valid,
            NSLocalizedString("error_email", comment: "Enter a valid email"))
        return valid
    }


    private func validatePassword(_ password: String) -> Bool {
        let valid = password.count >= 8
        updateField(passwordTextField, passwordErrorLabel, valid,
            NSLocalizedString("error_password", comment: "Min 8 chars"))
        return valid
    }


    private func validateRepeatPassword(_ pw: String, _ rep: String) -> Bool {
        let valid = !pw.isEmpty && pw == rep
        updateField(repeatPasswordTextField, repeatPwErrorLabel, valid,
            NSLocalizedString("error_repeat_password", comment: "Passwords don’t match"))
        return valid
    }


    private func updateField(_ field: UITextField,
                             _ label: UILabel,
                             _ valid: Bool,
                             _ message: String) {
        if valid {
            field.layer.borderColor = UIColor.gray.cgColor
            label.isHidden = true
        } else {
            field.layer.borderColor = UIColor.systemRed.cgColor
            label.text = message
            label.isHidden = false
            field.shake()
        }
    }

    // MARK: – Button loading helper
    private func setLoading(_ loading: Bool, on button: UIButton) {
        if loading {
            button.isEnabled = false
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.tag = 999
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            button.addSubview(spinner)

            NSLayoutConstraint.activate([
                spinner.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 4),
                spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
            button.titleLabel?.alpha = 0
        } else {
            button.isEnabled = true
            button.titleLabel?.alpha = 1
            button.viewWithTag(999)?.removeFromSuperview()
        }
    }

    // MARK: – Back navigation
    @objc private func backButtonTapped() {
        // Views to fade out (signup button remains for slide‑down effect)
        let toFade: [UIView] = [
            nameTextField, surnameTextField,
            emailTextField, emailErrorLabel,
            passwordTextField, passwordErrorLabel,
            repeatPasswordTextField, repeatPwErrorLabel,
            googleButton,
            backButton
        ]

        titleTopConstraint.isActive = false
        titleCenterConstraint.isActive = true
        signUpBottomConstraint.constant = -10

        UIView.animate(withDuration: 0.4, animations: {
            toFade.forEach { $0.alpha = 0 }
            self.view.layoutIfNeeded()
        }) { _ in
            if let nav = self.navigationController {
                nav.popViewController(animated: false)
            } else {
                self.dismiss(animated: false)
            }
        }
    }

    // MARK: – Main screen launch
    private func launchMainInterface() {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first,
            let initialVC = UIStoryboard(name: "ProfileSettings", bundle: nil).instantiateInitialViewController()
        else { return }

        let snapshot = window.snapshotView(afterScreenUpdates: true) ?? UIView()
        initialVC.view.addSubview(snapshot)
        window.rootViewController = initialVC
        window.makeKeyAndVisible()

        UIView.animate(withDuration: 0.4,
                       animations: {
                           snapshot.alpha = 0
                           snapshot.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                       },
                       completion: { _ in snapshot.removeFromSuperview() })
    }

    // MARK: – Toast error
    private func showGenericError() {
        let toast = UILabel()
        toast.text = NSLocalizedString("error_registration_failed", comment: "Registration failed message")
        toast.textColor = .white
        toast.backgroundColor = .systemRed
        toast.textAlignment = .center
        toast.layer.cornerRadius = 6
        toast.clipsToBounds = true
        toast.alpha = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            toast.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            toast.bottomAnchor.constraint(equalTo: signUpButton.topAnchor, constant: -16),
            toast.heightAnchor.constraint(equalToConstant: 34)
        ])

        UIView.animate(withDuration: 0.3,
                       animations: { toast.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3,
                           delay: 1.5,
                           options: []) {
                toast.alpha = 0
            } completion: { _ in toast.removeFromSuperview() }
        }
    }

    // MARK: – Factory helpers
    private static func makeField(placeholder: String, keyboard: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = UIFont(name: "Avenir", size: 18)
        tf.autocapitalizationType = .none
        tf.keyboardType = keyboard
        tf.borderStyle = .none
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 8
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }

    private static func makeSecureField(placeholder: String = "Password") -> UITextField {
        let tf = makeField(placeholder: placeholder)
        tf.isSecureTextEntry = true
        return tf
    }

    private static func makeErrorLabel() -> UILabel {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 12)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeAuthButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir", size: 14)
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor.systemOrange.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    // MARK: – UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            surnameTextField.becomeFirstResponder()
        case surnameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            repeatPasswordTextField.becomeFirstResponder()
        default:
            repeatPasswordTextField.resignFirstResponder()
        }
        return true
    }
}

// MARK: – Shake animation
private extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [-6, 6, -4, 4, -2, 2, 0]
        animation.duration = 0.3
        layer.add(animation, forKey: "shake")
    }
}

