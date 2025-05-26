//
//  CyclingFinishedViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//



import UIKit
import MapKit
import CoreData

class CyclingFinishedViewController: UIViewController, AddPictureViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    var cyclingSessionModel: CyclingSessionModel!
    var segments: [[CLLocationCoordinate2D]]!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var dontSaveButton: UIButton!
    var saveButton: UIButton!
    var nameTextField: UITextField!
    var statsContainer: UIStackView!
    var routeMapView: RouteMapView!
    var circleIndicators: CircleIndicatorsView!
    var addPictureView: AddPictureView!

    private var currentViewIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestureRecognizers()
        overrideUserInterfaceStyle = .dark
        routeMapView.segments = segments
    }

    private func setupUI() {
        setupBackgroundImage()
        setupNameTextField()
        setupStatsLabel()
        setupButtons()
        setupRouteMapView()
        setupAddPictureView()
        setupCircleIndicators()
    }

    private func setupBackgroundImage() {
        let backgroundImageView = UIImageView(image: UIImage(named: "no_data_cycling"))
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func setupStatsLabel() {
        statsContainer = UIStackView()
        statsContainer.axis = .vertical
        statsContainer.spacing = 5
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsContainer)

        let statsData = [
            ("Date", DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)),
            ("Time", cyclingSessionModel.time),
            ("Average Pace", cyclingSessionModel.avgPace),
            ("Average Speed", cyclingSessionModel.avgSpeed),
            ("Distance", cyclingSessionModel.distance),
            ("Max Speed", cyclingSessionModel.maxSpeed),
            ("Elevation Gain", cyclingSessionModel.totalElevationGain),
            ("Max Heart Rate", cyclingSessionModel.maxHeartRate),
            ("Average Heart Rate", cyclingSessionModel.averageHeartRate)
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
            statsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            statsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            statsContainer.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20)
        ])
    }

    private func setupRouteMapView() {
        routeMapView = RouteMapView()
        routeMapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(routeMapView)

        NSLayoutConstraint.activate([
            routeMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            routeMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            routeMapView.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 20),
            routeMapView.bottomAnchor.constraint(equalTo: dontSaveButton.topAnchor, constant: -20)
        ])
    }

    private func setupAddPictureView() {
        addPictureView = AddPictureView()
        addPictureView.delegate = self
        addPictureView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addPictureView)

        NSLayoutConstraint.activate([
            addPictureView.leadingAnchor.constraint(equalTo: routeMapView.leadingAnchor),
            addPictureView.trailingAnchor.constraint(equalTo: routeMapView.trailingAnchor),
            addPictureView.topAnchor.constraint(equalTo: routeMapView.topAnchor),
            addPictureView.bottomAnchor.constraint(equalTo: routeMapView.bottomAnchor)
        ])
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

    private func setupCircleIndicators() {
        circleIndicators = CircleIndicatorsView()
        circleIndicators.numberOfIndicators = 2
        circleIndicators.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circleIndicators)

        NSLayoutConstraint.activate([
            circleIndicators.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleIndicators.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 15),
            circleIndicators.heightAnchor.constraint(equalToConstant: 20),
            circleIndicators.widthAnchor.constraint(equalToConstant: 50)
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

    @objc func dontSaveTapped() {
        performSegue(withIdentifier: "FreeCyclingFinishedToHistorySegue", sender: self)
    }
    
    // MARK: - AddPictureViewDelegate

    func didSelectChooseFromLibrary() {
        openPhotoLibrary()
    }

    func didSelectTakePhoto() {
        openCamera()
    }
    // MARK: - Photo Library

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
    
    @objc func saveTapped() {

        guard (nameTextField.text?.count ?? 0) <= 40 else {
            showAlert(title: "Invalid Name",
                      message: "The workout name cannot exceed 40 characters.")
            return
        }

        saveButton.isEnabled = false

        let ok = WorkoutStorage.shared.save(
            workoutKind:     "cycling",
            name:     nameTextField.text,
            session:  cyclingSessionModel,
            segments: segments,
            picture:  addPictureView.getImage())

        if ok {
            performSegue(withIdentifier: "FreeCyclingFinishedToHistorySegue",
                         sender: self)
        } else {
            saveButton.isEnabled = true
            showAlert(title: "Error", message: "Failed to save workout.")
        }
    }



    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FreeCyclingFinishedToHistorySegue",
           let tabBarVC = segue.destination as? UITabBarController {
            tabBarVC.selectedIndex = 1
        }
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

//    private func saveWorkoutData() -> Bool {
//        let newWorkout = CyclingWorkOutEntity(context: context)
//        newWorkout.name = nameTextField.text?.isEmpty == false ? nameTextField.text : "Cycling Workout"
//        newWorkout.date = Date()
//        newWorkout.avgPace = cyclingSessionModel.avgPace
//        newWorkout.avgSpeed = cyclingSessionModel.avgSpeedInKmh
//        newWorkout.distance = cyclingSessionModel.totalDistanceInKm
//        newWorkout.elevationGain = Int32(cyclingSessionModel.totalElevationGainInMeters)
//        newWorkout.avarageHeartRate = Int32(cyclingSessionModel.avgHeartRateValue)
//        newWorkout.maxHeartRate = Int32(cyclingSessionModel.maxHeartRateValue)
//        newWorkout.maxSpeed = cyclingSessionModel.maxSpeedValue
//
//        if let segments = segments {
//            let segmentsArray = segments.map { segment in
//                segment.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
//            }
//            do {
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
//            print("Failed to save: \(error)")
//            return false
//        }
//    }
}
