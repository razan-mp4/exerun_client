//
//  WorkOutFinishedViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 13/1/2024.
//

import UIKit
import CoreData

class QuickWorkOutFinishedViewController: UIViewController, UITextFieldDelegate, AddPictureViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var timeTracker: QuickWorkoutModel!
    
    // Access Core Data context
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // Define UI components
    var dontSaveButton: UIButton!
    var saveButton: UIButton!
    var nameTextField: UITextField!
    var statsContainer: UIStackView!
    var addPictureView: AddPictureView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        overrideUserInterfaceStyle = .dark // Force dark mode
    }

    private func setupUI() {
        setupBackgroundImage()
        setupNameTextField()
        setupStatsLabel()
        setupButtons()
        setupAddPictureView()
    }
    
    private func setupBackgroundImage() {
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
    }
    
    private func setupNameTextField() {
        nameTextField = UITextField()
        nameTextField.placeholder = "Enter workout name"
        nameTextField.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        nameTextField.font = UIFont(name: "Avenir", size: 18)
        nameTextField.textAlignment = .center
        nameTextField.layer.cornerRadius = 20
        nameTextField.clipsToBounds = true
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.delegate = self
        view.addSubview(nameTextField)
        
        NSLayoutConstraint.activate([
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // UITextFieldDelegate method to dismiss keyboard when Return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func setupStatsLabel() {
        statsContainer = UIStackView()
        statsContainer.axis = .vertical
        statsContainer.alignment = .fill
        statsContainer.distribution = .fillEqually
        statsContainer.spacing = 5
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsContainer)
        
        let statsData = [
            ("Work Time", "\(timeTracker.workMinutes ?? 0)m \(timeTracker.workSeconds ?? 0)s"),
            ("Rest Time", "\(timeTracker.restMinutes ?? 0)m \(timeTracker.restSeconds ?? 0)s"),
            ("Sets", "\(timeTracker.totalSets ?? 0)")
        ]
        
        for (labelText, valueText) in statsData {
            let statStack = UIStackView()
            statStack.axis = .horizontal
            statStack.alignment = .fill
            statStack.distribution = .equalSpacing
            
            let label = UILabel()
            label.text = "\(labelText):"
            label.font = UIFont(name: "Avenir", size: 16)
            label.textAlignment = .left
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let value = UILabel()
            value.text = valueText
            value.font = UIFont(name: "Avenir", size: 16)
            value.textAlignment = .right
            value.translatesAutoresizingMaskIntoConstraints = false
            
            statStack.addArrangedSubview(label)
            statStack.addArrangedSubview(value)
            statsContainer.addArrangedSubview(statStack)
        }
        
        NSLayoutConstraint.activate([
            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            statsContainer.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20)
        ])
    }

    private func setupAddPictureView() {
        addPictureView = AddPictureView()
        addPictureView.delegate = self
        addPictureView.isHidden = false
        addPictureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addPictureView)
        
        NSLayoutConstraint.activate([
            addPictureView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            addPictureView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            addPictureView.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 20),
            addPictureView.bottomAnchor.constraint(equalTo: dontSaveButton.topAnchor, constant: -20)
        ])
    }
    
    // MARK: - AddPictureViewDelegate Methods

    func didSelectChooseFromLibrary() {
        openPhotoLibrary()
    }

    func didSelectTakePhoto() {
        openCamera()
    }
    
    private func openPhotoLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }

    // MARK: - UIImagePickerControllerDelegate Methods

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let selectedImage = info[.originalImage] as? UIImage {
            addPictureView.setImage(selectedImage)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    private func setupButtons() {
        dontSaveButton = UIButton(type: .system)
        dontSaveButton.setTitle("Don't Save", for: .normal)
        dontSaveButton.setTitleColor(.white, for: .normal)
        dontSaveButton.backgroundColor = .systemGray4
        dontSaveButton.titleLabel?.font = UIFont(name: "Avenir", size: 19)
        dontSaveButton.translatesAutoresizingMaskIntoConstraints = false
        dontSaveButton.layer.cornerRadius = 20
        dontSaveButton.addTarget(self, action: #selector(dontSaveTapped), for: .touchUpInside)
        view.addSubview(dontSaveButton)
        
        saveButton = UIButton(type: .system)
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemOrange
        saveButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.layer.cornerRadius = 20
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            dontSaveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -70),
            dontSaveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            dontSaveButton.widthAnchor.constraint(equalToConstant: 110),
            dontSaveButton.heightAnchor.constraint(equalToConstant: 40),
            
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 70),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            saveButton.widthAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Button Actions
    
    @objc func dontSaveTapped() {
        performSegue(withIdentifier: "QuickWorkOutFinishedToHistorySegue", sender: self)
    }
    
    
    @objc func saveTapped() {

        guard (nameTextField.text?.count ?? 0) <= 40 else {
            showAlert(title: "Invalid Name",
                      message: "The workout name cannot exceed 40 characters.")
            return
        }

        saveButton.isEnabled = false

        let ok = WorkoutStorage.shared.save(
            workoutKind:     "quick",
            name:     nameTextField.text,
            session:  timeTracker,          // QuickWorkoutModel conforms
            segments: nil,
            picture:  addPictureView.getImage())

        if ok {
            performSegue(withIdentifier: "QuickWorkOutFinishedToHistorySegue", sender: self)
        } else {
            saveButton.isEnabled = true
            showAlert(title: "Error", message: "Failed to save workout.")
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "QuickWorkOutFinishedToHistorySegue",
           let tabBarVC = segue.destination as? UITabBarController {
            tabBarVC.selectedIndex = 1
        }
    }
    // MARK: - Helper Alert Function

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Core Data Save Function

//    private func saveWorkoutData() -> Bool {
//        let newWorkout = QuickWorkOutEntity(context: context)
//        newWorkout.name = nameTextField.text?.isEmpty == false ? nameTextField.text : "Quick Workout"
//        newWorkout.date = Date()
//        
//        newWorkout.workTime = Int32(timeTracker.workMinutes * 60 + timeTracker.workSeconds)
//        newWorkout.restTime = Int32(timeTracker.restMinutes * 60 + timeTracker.restSeconds)
//        newWorkout.quantity = Int32(timeTracker.totalSets)
//
//        // Save image data if available
//        if let selectedImage = addPictureView.getImage() {
//            newWorkout.imageData = selectedImage.jpegData(compressionQuality: 0.8)
//        }
//
//        do {
//            try context.save()
//            print("Workout saved successfully")
//            return true
//        } catch {
//            print("Failed to save workout: \(error.localizedDescription)")
//            return false
//        }
//    }
}
