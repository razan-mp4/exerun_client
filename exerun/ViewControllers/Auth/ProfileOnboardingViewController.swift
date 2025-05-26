//
//  ProfileOnboardingViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 22/4/2025.
//

import UIKit

final class ProfileOnboardingViewController: UIViewController {

    private var isTransitioning = false

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
        button.setTitle(NSLocalizedString("back_button", comment: "Back button title"), for: .normal)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        return button
    }()

    private let containerView = UIView()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemOrange
        button.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Step Views
    private var steps: [UIView] = []
    private var currentStepIndex = 0
    private var previousStepWasReview = false
    private var editingFromReview = false

    // MARK: - Data
    struct ProfileInput {
        var height: Int?
        var weight: Int?
        var birthday: Date?
        var gender: String?
        var isComplete: Bool {
            return height != nil && weight != nil && birthday != nil && gender != nil
        }
    }
    
    private var profileData = ProfileInput()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadSteps()
        showStep(index: currentStepIndex)
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(containerView)
        view.addSubview(nextButton)

        containerView.translatesAutoresizingMaskIntoConstraints = false

        let pad: CGFloat = 40
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            containerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20),

            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        nextButton.setTitle(NSLocalizedString("next_button", comment: "Next or Submit button title"), for: .normal)

        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
    }

    private func loadSteps() {
        steps = [
            HeightStepView(onSelect: { [weak self] value in self?.profileData.height = value }),
            WeightStepView(onSelect: { [weak self] value in self?.profileData.weight = value }),
            BirthdayStepView(onSelect: { [weak self] date in self?.profileData.birthday = date }),
            GenderStepView(onSelect: { [weak self] value in self?.profileData.gender = value }),
            FinalReviewView(
                dataProvider: { [weak self] in self?.profileData ?? .init() },
                onEdit: { [weak self] stepIndex in
                    self?.previousStepWasReview = true
                    self?.editingFromReview = true
                    self?.showStep(index: stepIndex)
                }
            )
        ]
    }

    private func showStep(index: Int) {
        guard !isTransitioning else { return } // prevent multiple calls
        isTransitioning = true

        let oldStepView = containerView.subviews.first
        currentStepIndex = index
        let newStepView = steps[index]

        if let reviewView = newStepView as? FinalReviewView {
            reviewView.updateView()
        }

        newStepView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(newStepView)

        NSLayoutConstraint.activate([
            newStepView.topAnchor.constraint(equalTo: containerView.topAnchor),
            newStepView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newStepView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newStepView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        newStepView.alpha = 0
        newStepView.transform = CGAffineTransform(translationX: 30, y: 0)

        UIView.animate(withDuration: 0.3, animations: {
            newStepView.alpha = 1
            newStepView.transform = .identity
            oldStepView?.alpha = 0
            oldStepView?.transform = CGAffineTransform(translationX: -30, y: 0)
        }, completion: { _ in
            oldStepView?.removeFromSuperview()
            self.isTransitioning = false
        })

        backButton.isHidden = (index == 0 && !editingFromReview)
        nextButton.setTitle((index == steps.count - 1 || editingFromReview) ? NSLocalizedString("submit_button", comment: "Submit button title on last step") : NSLocalizedString("next_button", comment: "Next button title"), for: .normal)

    }


    @objc private func handleNext() {
        if editingFromReview {
            editingFromReview = false
            previousStepWasReview = false
            showStep(index: steps.count - 1) // Back to review
        } else if currentStepIndex == steps.count - 1 {
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            let entry = WeightEntry(date: formatter.string(from: today), value: 65.0)

            let request = ProfileUpdateRequest(
                height: profileData.height,
                weight: [entry],  
                birthday: profileData.birthday.map { formatter.string(from: $0) },
                gender: profileData.gender,
                profile_picture_url: nil 
            )

            ExerunServerAPIManager.shared.updateProfile(data: request) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        print("Profile updated:", profile)
                        ProfileStorage.shared.save(profile)
                        self.launchMainInterface()

                    case .failure(let error):
                        print("Failed to update profile:", error)
                    }
                }
            }



        } else {
            previousStepWasReview = false
            showStep(index: currentStepIndex + 1)
        }
    }


    @objc private func handleBack() {
        if editingFromReview {
            editingFromReview = false
            previousStepWasReview = false
            showStep(index: steps.count - 1)
        } else if previousStepWasReview {
            previousStepWasReview = false
            showStep(index: steps.count - 1)
        } else if currentStepIndex > 0 {
            showStep(index: currentStepIndex - 1)
        }
    }
    
    private func launchMainInterface() {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = windowScene.windows.first,
            let initialVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        else { return }

        initialVC.modalPresentationStyle = .fullScreen

        let snapshot = window.snapshotView(afterScreenUpdates: true) ?? UIView()
        initialVC.view.addSubview(snapshot)

        window.rootViewController = initialVC
        window.makeKeyAndVisible()

        UIView.animate(withDuration: 0.4, delay: 0,
                       options: [.curveEaseInOut]) {
            snapshot.alpha = 0
            snapshot.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            snapshot.removeFromSuperview()
        }
    }

}
