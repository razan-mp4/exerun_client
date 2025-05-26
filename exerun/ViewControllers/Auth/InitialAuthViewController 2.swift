//
//  InitialAuthViewController 2.swift
//  exerun
//
//  Created by Nazar Odemchuk on 16/4/2025.
//


import UIKit

class InitialAuthViewController: UIViewController {

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Basic View Setup
        view.backgroundColor = .white
        
        // 2. Create the Title Label
        let titleLabel = UILabel()
        titleLabel.text = "exerun"
        titleLabel.font = UIFont(name: "Avenir", size: 32)
        titleLabel.textColor = .systemOrange
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. Create the Buttons
        let signInButton = createStyledButton(withTitle: "Sign in", action: #selector(signInTapped))
        let signUpButton = createStyledButton(withTitle: "Sign up", action: #selector(signUpTapped))
        
        // 4. Add Subviews
        view.addSubview(titleLabel)
        view.addSubview(signInButton)
        view.addSubview(signUpButton)
        
        // 5. Layout (Auto Layout Constraints)
        NSLayoutConstraint.activate([
            // Title Label: place near top center
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            
            // Sign In Button
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            signInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            signInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            signInButton.heightAnchor.constraint(equalToConstant: 50),

            // Sign Up Button: below sign in
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUpButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 20),
            signUpButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            signUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            signUpButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // MARK: - Helper: Create Styled Button
    private func createStyledButton(with
