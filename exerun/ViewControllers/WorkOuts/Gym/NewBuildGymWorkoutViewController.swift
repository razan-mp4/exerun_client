//
//  NewBuildGymWorkoutViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//
import UIKit


final class NewBuildGymWorkoutViewController: UIViewController {
    private var steps: [UIView] = []
    private var currentStepIndex = 0

    private var selectedGoal: String?
    private var trainingDays: Int?

    private let containerView = UIView()
    private let nextButton = UIButton()
    private let loadingOverlay = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private var generatedPlan: GymPlanResponse?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        guard ProfileStorage.shared.getProfile() != nil else {
            showAlert(title: "Profile Incomplete", message: "Please complete your profile before generating a plan.")
            nextButton.isEnabled = false
            return
        }

        setupUI()
        setupSteps()
        showStep(0)
    }

    private func setupUI() {
        let backgroundImageView = UIImageView(image: UIImage(named: "rope_jumping"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)

        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let titleLabel: UILabel = {
            let label = UILabel()
            label.text = "exerun"
            label.font = UIFont(name: "Avenir", size: 32)
            label.textAlignment = .center
            label.textColor = .systemOrange
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        let backButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle(NSLocalizedString("back_button", comment: "Back button title"), for: .normal)
            button.setTitleColor(.systemOrange, for: .normal)
            button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
            return button
        }()

        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor = .systemOrange
        nextButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        nextButton.layer.cornerRadius = 20
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)

        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Loading overlay setup
        loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.isHidden = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        loadingOverlay.addSubview(activityIndicator)

        view.addSubview(titleLabel)
        view.addSubview(backButton)
        view.addSubview(containerView)
        view.addSubview(nextButton)
        view.addSubview(loadingOverlay)

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
            nextButton.heightAnchor.constraint(equalToConstant: 50),

            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor)
        ])
    }

    private func setupSteps() {
        steps = [
            GoalSelectionView { [weak self] goal in self?.selectedGoal = goal },
            TrainingDaysView { [weak self] days in self?.trainingDays = days }
        ]
    }

    private func showStep(_ index: Int) {
        containerView.subviews.forEach { $0.removeFromSuperview() }
        let view = steps[index]
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        currentStepIndex = index
        nextButton.setTitle(index == steps.count - 1 ? "Generate Plan" : "Next", for: .normal)
    }

    @objc private func handleNext() {
        if currentStepIndex < steps.count - 1 {
            showStep(currentStepIndex + 1)
        } else {
            submitRequest()
        }
    }

    private func submitRequest() {
        guard let profile = ProfileStorage.shared.getProfile() else {
            showAlert(title: "Missing Profile", message: "Please complete your profile first.")
            return
        }

        let height = Int(profile.height)
        let weight = Int(profile.weight)
        let gender = profile.gender ?? "male"
        let birthday = profile.birthday ?? Date(timeIntervalSince1970: 0)

        let goal = selectedGoal ?? "keep_form"
        let days = trainingDays ?? 3
        let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 25

        let req = GymPlanRequest(
            height: height,
            weight: weight,
            age: age,
            gender: gender,
            goal: goal,
            working_days: days
        )

        loadingOverlay.isHidden = false
        activityIndicator.startAnimating()
        nextButton.isEnabled = false

        ExerunServerAPIManager.shared.generateGymPlan(request: req) { result in
            DispatchQueue.main.async {
                self.loadingOverlay.isHidden = true
                self.activityIndicator.stopAnimating()
                self.nextButton.isEnabled = true

                switch result {
                case .success(let plan):
                    self.generatedPlan = plan
                    self.performSegue(withIdentifier: "ShowBuiltGymWorkoutSeque", sender: plan)
                case .failure(let error):
                    self.showAlert(title: "Error", message: "Failed to generate plan. Try again.\n\(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func handleBack() {
        if currentStepIndex > 0 {
            showStep(currentStepIndex - 1)
        } else {
            dismiss(animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowBuiltGymWorkoutSeque",
           let destVC = segue.destination as? GymPlanDetailViewController,
           let plan = sender as? GymPlanResponse {
            print(plan)
            destVC.plan = plan
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
