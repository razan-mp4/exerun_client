//
//  WorkOutViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 5/1/2024.
//

import UIKit

class WorkOutViewController: UIViewController, RobotHelpProvider, UIScrollViewDelegate {
    
    private var separatorLine: UIView!
    private var workoutsTitleLabel: UILabel!

    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private var workoutViews: [UIImageView] = []
    private var draggedView: UIImageView?
    private var autoScrollTimer: Timer?

    private var robotHeightConstraint: NSLayoutConstraint!

    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "exerun"
        lbl.font = UIFont(name: "Avenir", size: 32)
        lbl.textColor = .systemOrange
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "settings_icon") ?? UIImage(systemName: "gearshape")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let robotContainer = UIView()
    private var robotView: RobotView { RobotEnvironment.sharedRobotView }

    override func viewDidLoad() {
        super.viewDidLoad()

        robotView.configure(file: "robot.usdc")
        view.backgroundColor = .systemBackground

        setupHeader()         // 🟢 FIRST
        attachRobotView()     // 🟢 SECOND – only after titleLabel exists!
        setupScrollView()
        setupImageViews()

        robotView.helpProvider = self
    }


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        attachRobotView()
        robotView.helpProvider = self 
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        robotView.stopSpeaking()           // ② abort any ongoing help
    }

    // MARK: RobotHelpProvider
    func robotHelpScript() -> [String] {
        [
            NSLocalizedString("home_help_1", comment: "Main screen help 1"),
            NSLocalizedString("home_help_2", comment: "Main screen help 2"),
            NSLocalizedString("home_help_3", comment: "Main screen help 3")
        ]
    }

    
    // MARK: – UI helpers
    private func attachRobotView() {
        robotContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(robotContainer)

        NSLayoutConstraint.activate([
            robotContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            robotContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            robotContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])

        robotView.removeFromSuperview()
        robotView.translatesAutoresizingMaskIntoConstraints = false
        robotContainer.addSubview(robotView)

        NSLayoutConstraint.activate([
            robotView.topAnchor.constraint(equalTo: robotContainer.topAnchor),
            robotView.leadingAnchor.constraint(equalTo: robotContainer.leadingAnchor),
            robotView.trailingAnchor.constraint(equalTo: robotContainer.trailingAnchor),
            robotView.bottomAnchor.constraint(equalTo: robotContainer.bottomAnchor),
            robotView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }



    private func setupHeader() {
        view.addSubview(titleLabel)
        view.addSubview(settingsButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            settingsButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 28),
            settingsButton.heightAnchor.constraint(equalToConstant: 28),
        ])

        updateSetButColor(for: traitCollection)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
    }

    @objc private func openSettings() {
        performSegue(withIdentifier: "showSettingsFromWorkOut", sender: self)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y

        let originalHeight: CGFloat = 285
        let minHeight: CGFloat = 170

//        // Calculate new height
//        let newHeight = max(originalHeight - offsetY, minHeight)
//
//        // Update the robot view height
//        robotHeightConstraint.constant = newHeight
    }


    
    private func setupScrollView() {

        // Separator Line (fixed)
        separatorLine = UIView()
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.backgroundColor = .systemOrange
        view.addSubview(separatorLine)

        // ScrollView (contains workoutsTitleLabel and stackView)
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)

        
        // Workouts Title (inside scrollView)
        workoutsTitleLabel = UILabel()
        workoutsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        workoutsTitleLabel.text = NSLocalizedString("workouts_title", comment: "Title for workouts section")
        workoutsTitleLabel.font = UIFont(name: "Avenir-Heavy", size: 33.0)
        workoutsTitleLabel.textAlignment = .left
        scrollView.addSubview(workoutsTitleLabel)

        // StackView
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        // Constraints
        NSLayoutConstraint.activate([
            // separatorLine is pinned to robotView
            separatorLine.topAnchor.constraint(equalTo: robotContainer.bottomAnchor, constant: 8),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),

            // scrollView starts under separatorLine
            scrollView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // workoutsTitleLabel is inside scrollView
            workoutsTitleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: -3),
            workoutsTitleLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 10),
            workoutsTitleLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -10),
            workoutsTitleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -20),

            // stackView below workoutsTitleLabel
            stackView.topAnchor.constraint(equalTo: workoutsTitleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }


    private func setupImageViews() {
        let workouts: [(image: String, titleKey: String, descriptionKey: String, segueID: String, tag: Int)] = [
            ("main_quick", "quick_workout", "quick_workout_desc", "showQuickWorkOutViewController", 1),
            ("main_running", "running", "running_desc", "showRunningViewController", 2),
            ("main_workout", "gym_workout", "gym_workout_desc", "showGymWorkOutViewController", 3),
            ("main_hiking", "hike_walk", "hike_walk_desc", "showHikeWalkViewController", 4),
            ("main_cycling", "cycling", "cycling_desc", "showCyclingViewController", 5),
            ("main_skiing", "skiing", "skiing_desc", "showSkiingViewController", 6)
        ]


        let savedOrder = UserDefaults.standard.array(forKey: "WorkoutOrder") as? [Int] ?? workouts.map { $0.tag }
        let sortedWorkouts = savedOrder.compactMap { tag in workouts.first(where: { $0.tag == tag }) }

        workoutViews.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for workout in sortedWorkouts {
            let imageView = createImageView(imageName: workout.image, titleKey: workout.titleKey, descriptionKey: workout.descriptionKey, tag: workout.tag, segueID: workout.segueID)
            workoutViews.append(imageView)
            stackView.addArrangedSubview(imageView)
        }
    }

    private func createImageView(imageName: String, titleKey: String, descriptionKey: String, tag: Int, segueID: String) -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.tag = tag
        imageView.accessibilityIdentifier = segueID

        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(overlayView)

        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString(titleKey, comment: "Workout title")
        titleLabel.textColor = .systemOrange
        titleLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 28)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descriptionLabel = UILabel()
        descriptionLabel.text = NSLocalizedString(descriptionKey, comment: "Workout description")
        descriptionLabel.textColor = .white
        descriptionLabel.font = UIFont(name: "AvenirNext-Regular", size: 16)
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.addSubview(overlayView)
        overlayView.addSubview(titleLabel)
        overlayView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: -30),
            descriptionLabel.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            imageView.heightAnchor.constraint(equalToConstant: UIDevice.current.userInterfaceIdiom == .pad ? 340 : 150)
        ])

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        imageView.addGestureRecognizer(longPressGesture)

        return imageView
    }

    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedImageView = sender.view as? UIImageView,
              let segueIdentifier = tappedImageView.accessibilityIdentifier else { return }
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    @objc private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        guard let draggedView = sender.view as? UIImageView else { return }
        let location = sender.location(in: scrollView)

        switch sender.state {
        case .began:
            self.draggedView = draggedView
            startAutoScroll()
            UIView.animate(withDuration: 0.2) {
                draggedView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                draggedView.alpha = 0.7
            }
        case .changed:
            for (index, view) in workoutViews.enumerated() where view != draggedView {
                let viewFrame = view.frame.insetBy(dx: 0, dy: -10)
                if viewFrame.contains(location), let draggedIndex = workoutViews.firstIndex(of: draggedView) {
                    stackView.removeArrangedSubview(draggedView)
                    stackView.insertArrangedSubview(draggedView, at: index)
                    workoutViews.remove(at: draggedIndex)
                    workoutViews.insert(draggedView, at: index)
                    UIView.animate(withDuration: 0.2) {
                        self.stackView.layoutIfNeeded()
                    }
                    break
                }
            }
            scrollIfNeeded(location: location)
        case .ended, .cancelled:
            stopAutoScroll()
            UIView.animate(withDuration: 0.2) {
                draggedView.transform = .identity
                draggedView.alpha = 1.0
            }
            self.draggedView = nil
            saveWorkoutOrder()
        default:
            break
        }
    }

    private func saveWorkoutOrder() {
        let workoutOrder = workoutViews.map { $0.tag }
        UserDefaults.standard.set(workoutOrder, forKey: "WorkoutOrder")
        UserDefaults.standard.synchronize()
    }

    private func scrollIfNeeded(location: CGPoint) {
        let locationInView = scrollView.convert(location, to: view)
        let upperScrollThreshold: CGFloat = 140
        let lowerScrollThreshold: CGFloat = 10
        let maxScrollSpeed: CGFloat = 14

        if locationInView.y < upperScrollThreshold && scrollView.contentOffset.y > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: max(scrollView.contentOffset.y - maxScrollSpeed, 0)), animated: false)
        } else if locationInView.y > scrollView.bounds.height - lowerScrollThreshold {
            scrollView.setContentOffset(CGPoint(x: 0, y: min(scrollView.contentOffset.y + maxScrollSpeed, scrollView.contentSize.height - scrollView.bounds.height)), animated: false)
        }
    }

    private func startAutoScroll() {
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            if let location = self?.draggedView?.center {
                self?.scrollIfNeeded(location: location)
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func updateSetButColor(for traitCollection: UITraitCollection) {
        settingsButton.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateSetButColor(for: traitCollection)
    }
}
