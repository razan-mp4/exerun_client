//
//  GymViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 8/3/2025.
//

import UIKit

class NewGymViewController: UIViewController {
    private var buildWorkoutButton: UIButton!
    private var openWorkoutButton: UIButton!
    private var backButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        
        // Add the background image
        let backgroundImageView = UIImageView(image: UIImage(named: "rope_jumping"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        
        buildWorkoutButton = createStyledButton("Build Workout", action: #selector(buildWorkoutButtonTapped))
        openWorkoutButton = createStyledButton("Open Workout", action: #selector(openWorkoutButtonTapped))
        
        backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemOrange, for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        view.addSubview(backButton)
        view.addSubview(buildWorkoutButton)
        view.addSubview(openWorkoutButton)
        
        // Constraints for background and overlay
        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            buildWorkoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buildWorkoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buildWorkoutButton.bottomAnchor.constraint(equalTo: openWorkoutButton.topAnchor, constant: -10),
            
            openWorkoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            openWorkoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            openWorkoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])
    }
    
    private func createStyledButton(_ title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemOrange
        btn.titleLabel?.font = UIFont(name: "Avenir", size: 20)
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }
    @objc private func openWorkoutButtonTapped() {
        performSegue(withIdentifier: "OpenGymWorkoutSegue", sender: self)
    }
    
    @objc private func buildWorkoutButtonTapped() {
        performSegue(withIdentifier: "BuildGymWorkoutSegue", sender: self)
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
}
