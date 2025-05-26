//
//  GymPlanDetailViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//


import UIKit

final class GymPlanDetailViewController: UIViewController, UITextFieldDelegate {


    // MARK: – Public
    var plan: GymPlanResponse!          // <- injected from segue

    // MARK: – Private UI
    private let nameField     = UITextField()
    private let tableView   = UITableView(frame: .zero, style: .insetGrouped)
    private let saveButton  = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)

    // MARK: – Data
    private var workoutDays: [(title: String, exercises: [Exercise])] = []

    // MARK: – Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Background
        let bg = UIImageView(image: UIImage(named: "rope_jumping"))
        bg.contentMode = .scaleAspectFill
        bg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bg)

        // Add overlay to improve text visibility
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        
        NSLayoutConstraint.activate([
            // Background constraints
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            overlay.topAnchor.constraint(equalTo: bg.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: bg.bottomAnchor)
        ])
        
        parsePlan()
        setupNameField()
        setupTable()
        setupButtons()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: – Parse & Filter
    private func parsePlan() {
        // 1. Sort dictionary keys (day_1 … day_N)
        let sortedKeys = plan.workout_plan.days.keys.sorted { $0 < $1 }

        for key in sortedKeys {
            guard let exercises = plan.workout_plan.days[key] else { continue }
            // 2. Remove “rest_day”-only slots
            let activeExercises = exercises.filter { $0.name != "rest_day" }
            guard !activeExercises.isEmpty else { continue }

            // 3. Create user-friendly header  (Day 1  →  “Day 1”)
            if let dayNum = key.split(separator: "_").last {
                let title = "Day \(dayNum)"
                workoutDays.append((title, activeExercises))
            }
        }
    }

    // MARK: – Name Field
    private func setupNameField() {
        nameField.delegate = self
        nameField.placeholder = "Enter plan name"
        nameField.font        = UIFont(name: "Avenir", size: 22)
        nameField.borderStyle = .roundedRect
        nameField.translatesAutoresizingMaskIntoConstraints = false

        // Custom orange border
        nameField.layer.borderWidth = 1
        nameField.layer.cornerRadius = 10
        nameField.layer.borderColor = UIColor.systemOrange.cgColor

        view.addSubview(nameField)

        NSLayoutConstraint.activate([
            nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }


    
    // MARK: – TableView
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.rowHeight  = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 10),   // ⟸ below the text-field
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
    }

    // MARK: – Buttons
    private func setupButtons() {
        func style(_ button: UIButton, title: String, bg: UIColor) {
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = bg
            button.titleLabel?.font = UIFont(name: "Avenir", size: 21)
            button.layer.cornerRadius = 20
            button.translatesAutoresizingMaskIntoConstraints = false
        }

        style(saveButton,    title: "Save",    bg: .systemOrange)
        style(dismissButton, title: "Dismiss", bg: .systemGray4)

        saveButton.addTarget(self,    action: #selector(saveTapped),    for: .touchUpInside)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)

        view.addSubview(saveButton)
        view.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            dismissButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            dismissButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            dismissButton.widthAnchor.constraint(equalToConstant: 130),
            dismissButton.heightAnchor.constraint(equalToConstant: 44),

            saveButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            saveButton.bottomAnchor.constraint(equalTo: dismissButton.bottomAnchor),
            saveButton.widthAnchor.constraint(equalTo: dismissButton.widthAnchor),
            saveButton.heightAnchor.constraint(equalTo: dismissButton.heightAnchor),
        ])
    }

    // MARK: – Actions
    @objc private func dismissTapped() {
        performSegue(withIdentifier: "ReturnFromBuiltPlanSeque", sender: nil)
    }

    @objc private func saveTapped() {
        let planName = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !planName.isEmpty else {
            showAlert(title: "Name Required", message: "Please give your plan a name before saving.")
            return
        }

        // Save to Core Data (structured)
        GymPlanStorage.shared.saveStructured(planName: planName, response: plan)
        GymPlanSyncManager.shared.kick()
        
        let alert = UIAlertController(
            title: "Saved",
            message: "Workout plan '\(planName)' has been saved!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.performSegue(withIdentifier: "ReturnFromBuiltPlanSeque", sender: nil)
        })
        present(alert, animated: true)
    }

    
    // MARK: – Helpers
    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

}

// MARK: – UITableViewDataSource
extension GymPlanDetailViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { workoutDays.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        workoutDays[section].exercises.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let ex   = workoutDays[indexPath.section].exercises[indexPath.row]

        let text = "\(ex.name.replacingOccurrences(of: "_", with: " ").capitalized) – \(ex.sets) × \(ex.reps)"
        cell.textLabel?.text = text
        cell.textLabel?.font = UIFont(name: "Avenir", size: 18)
        cell.textLabel?.numberOfLines = 0
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        workoutDays[section].title
    }
}
