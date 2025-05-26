//
//  SkiingFinishedViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 30/1/2025.
//

import UIKit
import CoreLocation
import CoreData

class SkiingFinishedViewController: UIViewController, AddPictureViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    var skiingSessionModel: SkiingSessionModel!
    var segments: [[CLLocationCoordinate2D]]!

    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    private var nameTextField: UITextField!
    private var statsContainer: UIStackView!
    private var routeMapView: RouteMapView!
    private var addPictureView: AddPictureView!
    private var dontSaveButton: UIButton!
    private var saveButton: UIButton!
    private var circleIndicators: CircleIndicatorsView!
    private var currentViewIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestureRecognizers()
        overrideUserInterfaceStyle = .dark
        routeMapView.segments = segments
    }

    private func setupUI() {
        setupBackground()
        setupNameTextField()
        setupStats()
        setupButtons()
        setupRouteMapView()
        setupAddPictureView()
        setupCircleIndicators()
    }

    private func setupBackground() {
        let bgImage = UIImageView(image: UIImage(named: "no_data_skiing"))
        bgImage.contentMode = .scaleAspectFill
        bgImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bgImage)

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupNameTextField() {
        nameTextField = UITextField()
        nameTextField.placeholder = "Enter workout name"
        nameTextField.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        nameTextField.font = UIFont(name: "Avenir", size: 18)
        nameTextField.textAlignment = .center
        nameTextField.layer.cornerRadius = 20
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.delegate = self
        view.addSubview(nameTextField)

        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            nameTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupStats() {
        statsContainer = UIStackView()
        statsContainer.axis = .vertical
        statsContainer.spacing = 6
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsContainer)

        let statsData = [
            ("Date", DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)),
            ("Time", skiingSessionModel.time),
            ("Average Pace", skiingSessionModel.avgPace),
            ("Average Speed", skiingSessionModel.avgSpeed),
            ("Distance", skiingSessionModel.distance),
            ("Max Speed", skiingSessionModel.maxSpeed),
            ("Elevation Gain", skiingSessionModel.totalElevationGain),
            ("Max Heart Rate", skiingSessionModel.maxHeartRate),
            ("Average Heart Rate", skiingSessionModel.averageHeartRate),
            ("Min Elevation", skiingSessionModel.minElevation),
            ("Max Elevation", skiingSessionModel.maxElevation)
        ]

        for (label, value) in statsData {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.distribution = .equalSpacing

            let labelView = UILabel()
            labelView.text = "\(label):"
            labelView.font = UIFont(name: "Avenir", size: 16)

            let valueView = UILabel()
            valueView.text = value
            valueView.font = UIFont(name: "Avenir", size: 16)
            valueView.textAlignment = .right

            stack.addArrangedSubview(labelView)
            stack.addArrangedSubview(valueView)
            statsContainer.addArrangedSubview(stack)
        }

        NSLayoutConstraint.activate([
            statsContainer.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }

    private func setupRouteMapView() {
        routeMapView = RouteMapView()
        routeMapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(routeMapView)

        NSLayoutConstraint.activate([
            routeMapView.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 20),
            routeMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            routeMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            routeMapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
        ])
    }

    private func setupAddPictureView() {
        addPictureView = AddPictureView()
        addPictureView.delegate = self
        addPictureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addPictureView)

        NSLayoutConstraint.activate([
            addPictureView.topAnchor.constraint(equalTo: routeMapView.topAnchor),
            addPictureView.leadingAnchor.constraint(equalTo: routeMapView.leadingAnchor),
            addPictureView.trailingAnchor.constraint(equalTo: routeMapView.trailingAnchor),
            addPictureView.bottomAnchor.constraint(equalTo: routeMapView.bottomAnchor)
        ])
    }

    private func setupButtons() {
        dontSaveButton = createActionButton(title: "Don't Save", color: .systemGray4, selector: #selector(dontSaveTapped))
        saveButton = createActionButton(title: "Save", color: .systemOrange, selector: #selector(saveTapped))

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

    private func createActionButton(title: String, color: UIColor, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir", size: 18)
        button.backgroundColor = color
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: selector, for: .touchUpInside)
        view.addSubview(button)
        return button
    }

    private func setupCircleIndicators() {
        circleIndicators = CircleIndicatorsView()
        circleIndicators.numberOfIndicators = 2
        circleIndicators.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circleIndicators)

        NSLayoutConstraint.activate([
            circleIndicators.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleIndicators.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 10),
            circleIndicators.widthAnchor.constraint(equalToConstant: 50),
            circleIndicators.heightAnchor.constraint(equalToConstant: 20)
        ])
        circleIndicators.updatePageIndicators(activeIndex: currentViewIndex)
    }

    private func setupGestureRecognizers() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left && currentViewIndex == 0 {
            addPictureView.isHidden = false
            routeMapView.isHidden = true
            currentViewIndex = 1
        } else if gesture.direction == .right && currentViewIndex == 1 {
            addPictureView.isHidden = true
            routeMapView.isHidden = false
            currentViewIndex = 0
        }
        circleIndicators.updatePageIndicators(activeIndex: currentViewIndex)
    }

    // MARK: - Save Logic

    @objc private func dontSaveTapped() {
        performSegue(withIdentifier: "SkiingFinishedToHistorySegue", sender: self)
    }

    @objc private func saveTapped() {

        guard (nameTextField.text?.count ?? 0) <= 40 else {
            showAlert(title: "Invalid Name",
                      message: "The workout name cannot exceed 40 characters.")
            return
        }

        saveButton.isEnabled = false

        let ok = WorkoutStorage.shared.save(
            workoutKind:     "skiing",
            name:     nameTextField.text,
            session:  skiingSessionModel,
            segments: segments,
            picture:  addPictureView.getImage())

        if ok {
            performSegue(withIdentifier: "SkiingFinishedToHistorySegue", sender: self)
        } else {
            saveButton.isEnabled = true
            showAlert(title: "Error", message: "Failed to save workout.")
        }
    }
//
//
//    private func saveWorkOutData() -> Bool {
//        let newWorkout = SkiingWorkOutEntity(context: context)
//        newWorkout.name = nameTextField.text?.isEmpty == false ? nameTextField.text : "Skiing Workout"
//        newWorkout.date = Date()
//        newWorkout.avgSpeed = skiingSessionModel.avgSpeedInKmh
//        newWorkout.maxSpeed = skiingSessionModel.maxSpeedValue
//        newWorkout.distance = skiingSessionModel.totalDistanceInKm
//        newWorkout.elevationGain = Int32(skiingSessionModel.totalElevationGainInMeters)
//        newWorkout.avarageHeartRate = Int32(skiingSessionModel.avgHeartRateValue)
//        newWorkout.maxHeartRate = Int32(skiingSessionModel.maxHeartRateValue)
//
//        if let segments = segments {
//            do {
//                let segmentsArray = segments.map { segment in
//                    segment.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
//                }
//                let encoded = try NSKeyedArchiver.archivedData(withRootObject: segmentsArray, requiringSecureCoding: false)
//                newWorkout.segments = encoded
//            } catch {
//                print("Failed to encode segments: \(error)")
//                return false
//            }
//        }
//
//        if let selectedImage = addPictureView.getImage() {
//            newWorkout.imageData = selectedImage.jpegData(compressionQuality: 0.8)
//        }
//
//        do {
//            try context.save()
//            return true
//        } catch {
//            print("Failed to save: \(error.localizedDescription)")
//            return false
//        }
//    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SkiingFinishedToHistorySegue",
           let tabBarVC = segue.destination as? UITabBarController {
            tabBarVC.selectedIndex = 1
        }
    }

    // MARK: - Delegate methods
    func didSelectChooseFromLibrary() { openPhotoLibrary() }
    func didSelectTakePhoto() { openCamera() }

    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            addPictureView.setImage(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
