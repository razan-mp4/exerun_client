//
//  LoginViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 16/4/2025.
//

import UIKit
import GoogleSignIn

final class LoginViewController: UIViewController, UITextFieldDelegate {

    // MARK: – UI Elements
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "exerun"
        l.font = UIFont(name: "Avenir", size: 32)
        l.textColor = .systemOrange
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = NSLocalizedString("placeholder_email", comment: "Email field")
        tf.font = UIFont(name: "Avenir", size: 18)
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        tf.borderStyle = .none
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 8
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = NSLocalizedString("placeholder_password", comment: "Password field")
        tf.font = UIFont(name: "Avenir", size: 18)
        tf.autocapitalizationType = .none
        tf.isSecureTextEntry = true
        tf.borderStyle = .none
        tf.layer.borderColor = UIColor.gray.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 8
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let forgotPasswordButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(NSLocalizedString("button_forgot_password", comment: "Forgot password"), for: .normal)
        b.setTitleColor(.systemOrange, for: .normal)
        b.titleLabel?.font = UIFont(name: "Avenir", size: 14)
        b.contentHorizontalAlignment = .right
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var googleButton = createSmallAuthButton(title: NSLocalizedString("button_google_signin", comment: "Sign in with Google"))

    private let signInButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(NSLocalizedString("button_sign_in", comment: "Sign in"), for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .systemOrange
        b.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        b.layer.cornerRadius = 20
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle(NSLocalizedString("button_back", comment: "Back"), for: .normal)
        b.setTitleColor(.systemOrange, for: .normal)
        b.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return b
    }()

    // Error helper‑labels
    private let emailErrorLabel: UILabel = {
        let l = UILabel()
        l.textColor = .systemRed
        l.font = .systemFont(ofSize: 12)
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let passwordErrorLabel: UILabel = {
        let l = UILabel()
        l.textColor = .systemRed
        l.font = .systemFont(ofSize: 12)
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: – Constraints
    private var titleTopConstraint: NSLayoutConstraint!
    private var titleCenterConstraint: NSLayoutConstraint!
    private var signInBottomConstraint: NSLayoutConstraint!

    // MARK: – Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        emailTextField.delegate = self
        passwordTextField.delegate = self

        [titleLabel, emailTextField, emailErrorLabel, passwordTextField, passwordErrorLabel, forgotPasswordButton, googleButton, signInButton, backButton].forEach { view.addSubview($0) }

        setupConstraints()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)

        signInButton.addTarget(self,  action: #selector(handleEmailSignIn), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
    }

    // MARK: – Layout
    private func setupConstraints() {
        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        titleCenterConstraint = titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        titleTopConstraint.isActive = true

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            emailTextField.heightAnchor.constraint(equalToConstant: 45),

            emailErrorLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 4),
            emailErrorLabel.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            emailErrorLabel.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),

            passwordTextField.topAnchor.constraint(equalTo: emailErrorLabel.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 45),

            passwordErrorLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 4),
            passwordErrorLabel.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
            passwordErrorLabel.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),

            forgotPasswordButton.topAnchor.constraint(equalTo: passwordErrorLabel.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),

            googleButton.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 30),
            googleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleButton.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            googleButton.heightAnchor.constraint(equalToConstant: 40),

            signInButton.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            signInButton.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            signInButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        signInBottomConstraint = signInButton.bottomAnchor
            .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        signInBottomConstraint.isActive = true

        emailTextField.setLeftPaddingPoints(8)
        passwordTextField.setLeftPaddingPoints(8)
    }

    // MARK: – Actions
    @objc private func backButtonTapped() {
        let toHide: [UIView] = [emailTextField, emailErrorLabel, passwordTextField, passwordErrorLabel, forgotPasswordButton, googleButton, backButton]
        titleTopConstraint.isActive = false
        titleCenterConstraint.isActive = true
        signInBottomConstraint.constant = -80

        UIView.animate(withDuration: 0.4) {
            toHide.forEach { $0.alpha = 0 }
            self.view.layoutIfNeeded()
        } completion: { _ in
            toHide.forEach { $0.isHidden = true }
            if let nav = self.navigationController {
                nav.popViewController(animated: false)
            } else {
                self.dismiss(animated: false)
            }
        }
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

  
    //------------------------------------------------------------------
    // MARK: – Helpers to toggle a button’s loading state
    //------------------------------------------------------------------
    private func setLoading(_ loading: Bool, on button: UIButton) {
        if loading {
            // Disable interaction & add a centred spinner
            button.isEnabled = false
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            spinner.tag = 999   // so we can find/remove it later
            button.addSubview(spinner)

            NSLayoutConstraint.activate([
                spinner.leadingAnchor.constraint(equalTo: button.trailingAnchor,
                                                                     constant: 4),
                spinner.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
            // Fade the title to hint it’s disabled
            button.titleLabel?.alpha = 0.0
        } else {
            // Re‑enable, remove spinner
            button.isEnabled = true
            button.titleLabel?.alpha = 1.0
            button.viewWithTag(999)?.removeFromSuperview()
        }
    }
    
    // ──────────────────────────────────────────────────────────────────────────
    // MARK: – EMAIL / PASSWORD LOGIN
    // ──────────────────────────────────────────────────────────────────────────
    @objc private func handleEmailSignIn() {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        let emailOk = validateEmail(email)
        let passwordOk = validatePassword(password)

        guard emailOk && passwordOk else { return }

        setLoading(true, on: signInButton)

        ExerunServerAPIManager.shared.emailLogin(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.setLoading(false, on: self.signInButton)

                switch result {
                case .success:
                    ExerunServerAPIManager.shared.getCurrentUser { userResult in
                        DispatchQueue.main.async {
                            switch userResult {
                            case .success(let remoteUser):
                                UserStorage.shared.save(remoteUser)

                                ExerunServerAPIManager.shared.getCurrentProfile { profileResult in
                                    DispatchQueue.main.async {
                                        switch profileResult {
                                        case .success(let remoteProfile):
                                            ProfileStorage.shared.save(remoteProfile)

                                            if let url = remoteProfile.profile_picture_url {
                                                ExerunServerAPIManager.shared.downloadProfilePicture(urlString: url)
                                            }

                                            // Wait for pull to complete, but do NOT push any local workouts
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
                                            self.launchMainInterface()
                                        }
                                    }
                                }

                            case .failure:
                                self.showGenericError()
                            }
                        }
                    }

                case .failure:
                    self.updateField(self.emailTextField, errorLabel: self.emailErrorLabel, valid: false, message: "Invalid credentials")
                    self.updateField(self.passwordTextField, errorLabel: self.passwordErrorLabel, valid: false, message: NSLocalizedString("error_credentials", comment: "Invalid credentials"))
                }
            }
        }
    }



    private func showGenericError() {
        let alert = UIAlertController(title: NSLocalizedString("error", comment: "Error"),
                                       message: NSLocalizedString("error_generic", comment: "Something went wrong"),
                                       preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    
    // ──────────────────────────────────────────────────────────────────────────
    // MARK: – GOOGLE LOGIN (unchanged)
    // ──────────────────────────────────────────────────────────────────────────
    @objc private func handleGoogleSignIn() {
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
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        ExerunServerAPIManager.shared.getCurrentUser { userResult in
                            switch userResult {
                            case .success(let remoteUser):
                                UserStorage.shared.save(remoteUser)

                                ExerunServerAPIManager.shared.getCurrentProfile { profileResult in
                                    DispatchQueue.main.async {
                                        self.setLoading(false, on: self.googleButton)

                                        switch profileResult {
                                        case .success(let remoteProfile):
                                            ProfileStorage.shared.save(remoteProfile)

                                            if let url = remoteProfile.profile_picture_url {
                                                ExerunServerAPIManager.shared.downloadProfilePicture(urlString: url)
                                            }

                                            // Wait for pull to complete before resume
                                            // Wait for pull to complete, but do NOT push any local workouts
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

                    case .failure:
                        self.setLoading(false, on: self.googleButton)
                        self.showGenericError()
                    }
                }
            }
        }
    }



    // ──────────────────────────────────────────────────────────────────────────
    // MARK: – Validation helpers
    // ──────────────────────────────────────────────────────────────────────────
    private func validateEmail(_ email: String) -> Bool {
        let pattern = "(?:[A-Z0-9a-z._%+-]+)@(?:[A-Za-z0-9-]+\\.)+[A-Za-z]{2,64}"
        let ok = NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
        updateField(emailTextField,
                    errorLabel: emailErrorLabel,
                    valid: ok,
                    message: ok ? nil : NSLocalizedString("error_invalid_email", comment: "Invalid email format"))
        return ok
    }

    private func validatePassword(_ pw: String) -> Bool {
        let ok = pw.count >= 8
        updateField(passwordTextField,
                    errorLabel: passwordErrorLabel,
                    valid: ok,
                    message: ok ? nil : NSLocalizedString("error_short_password", comment: "Minimum 8 characters"))
        return ok
    }

    private func updateField(_ field: UITextField,
                             errorLabel: UILabel,
                             valid: Bool,
                             message: String?) {
        if valid {
            field.layer.borderColor = UIColor.gray.cgColor
            errorLabel.isHidden = true
        } else {
            field.layer.borderColor = UIColor.systemRed.cgColor
            errorLabel.text = message
            errorLabel.isHidden = false
            field.shake()
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: – Helpers
    // ──────────────────────────────────────────────────────────────────────────
    private func launchMainInterface() {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = windowScene.windows.first,
            let initialVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        else { return }

        initialVC.modalPresentationStyle = .fullScreen

        // Take a snapshot of the current screen for a smoother transition
        let snapshot = window.snapshotView(afterScreenUpdates: true) ?? UIView()
        initialVC.view.addSubview(snapshot)

        // Switch root view controller *before* starting the animation
        window.rootViewController = initialVC
        window.makeKeyAndVisible()

        // Cross‑dissolve & slight scale‑down effect
        UIView.animate(withDuration: 0.4, delay: 0,
                       options: [.curveEaseInOut]) {
            snapshot.alpha = 0
            snapshot.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            snapshot.removeFromSuperview()
        }
    }

    private func createSmallAuthButton(title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.systemOrange, for: .normal)
        b.titleLabel?.font = UIFont(name: "Avenir", size: 14)
        b.backgroundColor = .clear
        b.layer.borderColor = UIColor.systemOrange.cgColor
        b.layer.borderWidth = 1
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: – Shake animation
private extension UIView {
    func shake() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [-6, 6, -4, 4, -2, 2, 0]
        anim.duration = 0.3
        layer.add(anim, forKey: "shake")
    }
}

// MARK: – Padding helpers
extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.height))
        leftView = pad; leftViewMode = .always
    }
}
