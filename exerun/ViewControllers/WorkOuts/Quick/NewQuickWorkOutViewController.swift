//
//  NewQuickWorkOutViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/1/2024.
//

import UIKit

class NewQuickWorkOutViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    // UI Elements
    private let workLabel = UILabel()
    private let restLabel = UILabel()
    private let repeatLabel = UILabel()
    
    private let workMinutesPicker = UIPickerView()
    private let workSecondsPicker = UIPickerView()
    private let restMinutesPicker = UIPickerView()
    private let restSecondsPicker = UIPickerView()
    private let setsPicker = UIPickerView()
    private let startButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    // Time unit labels
    private let workMinLabel = UILabel()
    private let workSecLabel = UILabel()
    private let restMinLabel = UILabel()
    private let restSecLabel = UILabel()
    private let setsLabel = UILabel()

    // StackView to hold all centered elements
    private let centeredStackView = UIStackView()

    // Number options
    private let numbers = Array(0...59) // For minutes and seconds
    private let sets = Array(1...99)    // For sets

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPickers()
        setupBackButton() // Add the setup for the back button
    }

    private func setupUI() {
        
        // Add the background image
        let backgroundImageView = UIImageView(image: UIImage(named: "rope_jumping"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        
        // Add a dark overlay to improve visibility
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        // Constraints for background and overlay
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

        // Configure all labels with Avenir Book 20.0
        let allLabels = [workLabel, restLabel, repeatLabel, workMinLabel, workSecLabel, restMinLabel, restSecLabel, setsLabel]
        allLabels.forEach { label in
            label.font = UIFont(name: "Avenir-Book", size: 20)
            label.textAlignment = .center
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
        }
        
        workLabel.text = "Work"
        restLabel.text = "Rest"
        repeatLabel.text = "Repeat Times"
        workMinLabel.text = "min"
        workSecLabel.text = "sec"
        restMinLabel.text = "min"
        restSecLabel.text = "sec"
        setsLabel.text = "sets"
        
        // Configure Start Button (Styled like Stop Button)
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.backgroundColor = .systemOrange
        startButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        startButton.layer.cornerRadius = 20
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startWorkoutButtonTapped), for: .touchUpInside)
        view.addSubview(startButton)

        // Configure pickers
        [workMinutesPicker, workSecondsPicker, restMinutesPicker, restSecondsPicker, setsPicker].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // Create horizontal stack views for each row
        let workRow = UIStackView(arrangedSubviews: [workMinutesPicker, workMinLabel, workSecondsPicker, workSecLabel])
        let restRow = UIStackView(arrangedSubviews: [restMinutesPicker, restMinLabel, restSecondsPicker, restSecLabel])
        let setsRow = UIStackView(arrangedSubviews: [setsPicker, setsLabel])

        // Configure each row
        [workRow, restRow, setsRow].forEach { row in
            row.axis = .horizontal
            row.spacing = 10
            row.alignment = .center
            row.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Add labels and rows to the main centered stack view
        centeredStackView.axis = .vertical
        centeredStackView.alignment = .center
        centeredStackView.spacing = 20
        centeredStackView.translatesAutoresizingMaskIntoConstraints = false
        centeredStackView.addArrangedSubview(workLabel)
        centeredStackView.addArrangedSubview(workRow)
        centeredStackView.addArrangedSubview(restLabel)
        centeredStackView.addArrangedSubview(restRow)
        centeredStackView.addArrangedSubview(repeatLabel)
        centeredStackView.addArrangedSubview(setsRow)
        
        view.addSubview(centeredStackView)

        // Layout constraints for centered stack view and start button
        NSLayoutConstraint.activate([
            // Center the stack view horizontally and vertically in the view
            centeredStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centeredStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Width and height constraints for pickers
            workMinutesPicker.widthAnchor.constraint(equalToConstant: 70),
            workMinutesPicker.heightAnchor.constraint(equalToConstant: 95),
            workSecondsPicker.widthAnchor.constraint(equalToConstant: 70),
            workSecondsPicker.heightAnchor.constraint(equalToConstant: 95),
            restMinutesPicker.widthAnchor.constraint(equalToConstant: 70),
            restMinutesPicker.heightAnchor.constraint(equalToConstant: 95),
            restSecondsPicker.widthAnchor.constraint(equalToConstant: 70),
            restSecondsPicker.heightAnchor.constraint(equalToConstant: 95),
            setsPicker.widthAnchor.constraint(equalToConstant: 70),
            setsPicker.heightAnchor.constraint(equalToConstant: 95),

            // Start button constraints
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            startButton.widthAnchor.constraint(equalToConstant: 100),
            startButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupBackButton() {
        // Configure Back Button
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(UIColor.systemOrange, for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)

        // Constraints for the back button at the top-left corner
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }

    private func setupPickers() {
        [workMinutesPicker, workSecondsPicker, restMinutesPicker, restSecondsPicker, setsPicker].forEach {
            $0.dataSource = self
            $0.delegate = self
        }
    }

    // MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView == setsPicker ? sets.count : numbers.count
    }

    // MARK: - UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerView == setsPicker ? String(sets[row]) : String(numbers[row])
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let text = pickerView == setsPicker ? String(sets[row]) : String(numbers[row])
        let color =  UIColor.white
        return NSAttributedString(string: text, attributes: [
            .font: UIFont(name: "Avenir", size: 18) ?? UIFont.systemFont(ofSize: 18),
            .foregroundColor: color
        ])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let timerViewController = segue.destination as? TimerViewController {
            timerViewController.timeTracker = QuickWorkoutModel(
                restMinutes: restMinutesPicker.selectedRow(inComponent: 0),
                restSeconds: restSecondsPicker.selectedRow(inComponent: 0),
                workMinutes: workMinutesPicker.selectedRow(inComponent: 0),
                workSeconds: workSecondsPicker.selectedRow(inComponent: 0),
                totalSets: sets[setsPicker.selectedRow(inComponent: 0)]
            )
        }
    }

    @objc private func startWorkoutButtonTapped() {
        let workMinutes = workMinutesPicker.selectedRow(inComponent: 0)
        let workSeconds = workSecondsPicker.selectedRow(inComponent: 0)
        let restMinutes = restMinutesPicker.selectedRow(inComponent: 0)
        let restSeconds = restSecondsPicker.selectedRow(inComponent: 0)
        let totalSets = sets[setsPicker.selectedRow(inComponent: 0)]

        let totalWorkSeconds = (workMinutes * 60) + workSeconds
        let totalRestSeconds = (restMinutes * 60) + restSeconds
        
        if (totalWorkSeconds + totalRestSeconds) * totalSets < 60 {
            let alert = UIAlertController(title: "Invalid Workout", message: "Workout should be at least a minute", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "StartWorkoutSegue", sender: self)
        }
    }

    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
