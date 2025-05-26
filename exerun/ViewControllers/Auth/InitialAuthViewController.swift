//
//  InitialAuthViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 16/4/2025.
//

import UIKit

class InitialAuthViewController: UIViewController {
  
  // MARK: — UI

  private let titleLabel: UILabel = {
    let lbl = UILabel()
    lbl.text = "exerun"
    lbl.font = UIFont(name: "Avenir", size: 32)
    lbl.textColor = .systemOrange
    lbl.textAlignment = .center
    lbl.translatesAutoresizingMaskIntoConstraints = false
    return lbl
  }()
  
  private lazy var signInButton = createStyledButton(
    withTitle: NSLocalizedString("auth_signin", comment: "Sign in button"),
    action: #selector(signInTapped)
  )
  
  private lazy var signUpButton = createStyledButton(
    withTitle: NSLocalizedString("auth_signup", comment: "Sign up button"),
    action: #selector(signUpTapped)
  )
  
  // MARK: — Constraints to toggle

  private var titleCenterYConstraint: NSLayoutConstraint!
  private var titleTopConstraint: NSLayoutConstraint!
  
  private var signInBottomConstraint: NSLayoutConstraint!
  private var signUpTopConstraint: NSLayoutConstraint!
  private var signUpBottomConstraint: NSLayoutConstraint!
  
  
  // MARK: — Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(titleLabel)
    view.addSubview(signInButton)
    view.addSubview(signUpButton)
    setupConstraints()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // reset title
    titleTopConstraint.isActive = false
    titleCenterYConstraint.isActive = true
    // reset buttons
    signInBottomConstraint.constant = -80
    signUpBottomConstraint.isActive = false
    signUpTopConstraint.isActive = true
    signInButton.alpha = 1
    signUpButton.alpha = 1
    signInButton.isEnabled = true
    signUpButton.isEnabled = true
    view.layoutIfNeeded()
  }
  
  
  // MARK: — Layout

  private func setupConstraints() {
    // title: center-Y or top
    titleCenterYConstraint = titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    titleTopConstraint     = titleLabel.topAnchor.constraint(
      equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10
    )
    titleCenterYConstraint.isActive = true
    
    NSLayoutConstraint.activate([
      titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
    ])
    
    // signIn: leading/trailing/height
    NSLayoutConstraint.activate([
      signInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
      signInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
      signInButton.heightAnchor.constraint(equalToConstant: 50)
    ])
    // bottom at -80 initially
    signInBottomConstraint = signInButton.bottomAnchor.constraint(
      equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80
    )
    signInBottomConstraint.isActive = true
    
    // signUp: same width/height
    NSLayoutConstraint.activate([
      signUpButton.leadingAnchor.constraint(equalTo: signInButton.leadingAnchor),
      signUpButton.trailingAnchor.constraint(equalTo: signInButton.trailingAnchor),
      signUpButton.heightAnchor.constraint(equalTo: signInButton.heightAnchor)
    ])
    // initially pinned under signIn
    signUpTopConstraint = signUpButton.topAnchor.constraint(
      equalTo: signInButton.bottomAnchor, constant: 20
    )
    signUpTopConstraint.isActive = true
    
    // also prepare bottom constraint for signUp (inactive)
    signUpBottomConstraint = signUpButton.bottomAnchor.constraint(
      equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40
    )
    signUpBottomConstraint.isActive = false
  }
  
  
  // MARK: — Helpers

  private func createStyledButton(withTitle title: String, action: Selector) -> UIButton {
    let b = UIButton(type: .system)
    b.setTitle(title, for: .normal)
    b.setTitleColor(.white, for: .normal)
    b.backgroundColor = .systemOrange
    b.titleLabel?.font = UIFont(name: "Avenir", size: 21)
    b.layer.cornerRadius = 20
    b.translatesAutoresizingMaskIntoConstraints = false
    b.addTarget(self, action: action, for: .touchUpInside)
    return b
  }
  
  
  // MARK: — Actions

  @objc private func signInTapped() {
    animate(
      moving: signInButton,
      fading: signUpButton,
      moveSignUp: false
    ) {
      self.performSegue(withIdentifier: "ShowLoginScreenSeque", sender: nil)
    }
  }
  
  @objc private func signUpTapped() {
    animate(
      moving: signUpButton,
      fading: signInButton,
      moveSignUp: true
    ) {
      self.performSegue(withIdentifier: "ShowRegistrationScreenSeque", sender: nil)
    }
  }
  
  /// - Parameters:
  ///   - moving: the button to relocate to bottom -40
  ///   - fading: the button to fade out
  ///   - moveSignUp: `true` if `moving` is the signUpButton (so swap its constraints)
  private func animate(
    moving buttonToMove: UIButton,
    fading buttonToFade: UIButton,
    moveSignUp: Bool,
    completion: @escaping ()->Void
  ) {
    // disable both
    signInButton.isEnabled = false
    signUpButton.isEnabled = false
    
    // 1) title up
    titleCenterYConstraint.isActive = false
    titleTopConstraint.isActive = true
    
    // 2) move buttons
    if moveSignUp {
      // signUp: deactivate top, activate bottom
      signUpTopConstraint.isActive = false
      signUpBottomConstraint.isActive = true
    } else {
      // signIn: simply change constant
      signInBottomConstraint.constant = -40
    }
    
    // 3) fade out the other
    UIView.animate(withDuration: 0.5, animations: {
      self.view.layoutIfNeeded()
      buttonToFade.alpha = 0
    }, completion: { _ in
      completion()
    })
  }
}
