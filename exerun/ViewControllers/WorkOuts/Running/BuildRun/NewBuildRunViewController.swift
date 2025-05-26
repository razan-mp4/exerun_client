//
//  NewBuildRunViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 21/11/2024.
//

import UIKit
import CoreLocation

enum SelectionType {
    case startingPoint
    case finishingPoint
}

class NewBuildRunViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate {
    
    private var currentSelectionType: SelectionType?
    
    // Store the selected coordinates
    private var startingPointCoordinates: CLLocationCoordinate2D?
    private var finishingPointCoordinates: CLLocationCoordinate2D?
    
    // UI Elements
    private let titleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let distancePicker = UIPickerView()
    private let startingPointLabel = UILabel()
    private let startingPointTextField = UITextField()
    private let startingPointActionLabel = UILabel()
    private let currentLocationLabel = UILabel()
    private let finishingPointLabel = UILabel()
    private let finishingPointTextField = UITextField()
    private let finishingPointActionLabel = UILabel()
    private let buildButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)

    private let pointStackView = UIStackView()
    private let pickerStackView = UIStackView()
    private let mainStackView = UIStackView()
    
    // Number options for kilometers
    private let kilometers = Array(1...1000)
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBackButton()
        setupPickers()
        
        overrideUserInterfaceStyle = .dark // Force dark mode
        
        // Set default value for the picker to 10 km
        if let defaultRow = kilometers.firstIndex(of: 10) {
            distancePicker.selectRow(defaultRow, inComponent: 0, animated: false)
        }

        setupLocationServices()
    }

    private func setupUI() {
        // Add the background image
        let backgroundImageView = UIImageView(image: UIImage(named: "no_data_running"))
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)

        // Add a dark overlay on top of the image
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

        // Title label
        titleLabel.text = "Build Your Run"
        titleLabel.font = UIFont(name: "Avenir", size: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Configure starting point stack
        configurePointStackView()

        // Configure picker stack
        configurePickerStackView()

        // Combine point and picker stack views into mainStackView
        mainStackView.axis = .vertical
        mainStackView.spacing = 30
        mainStackView.alignment = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(pointStackView)
        mainStackView.addArrangedSubview(pickerStackView)
        view.addSubview(mainStackView)

        // Build button
        buildButton.setTitle("Build", for: .normal)
        buildButton.setTitleColor(.white, for: .normal)
        buildButton.backgroundColor = .systemOrange
        buildButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        buildButton.layer.cornerRadius = 20
        buildButton.translatesAutoresizingMaskIntoConstraints = false
        buildButton.addTarget(self, action: #selector(buildWorkoutButtonTapped), for: .touchUpInside)
        view.addSubview(buildButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Center main stack view vertically
            mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Start button
            buildButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buildButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            buildButton.widthAnchor.constraint(equalToConstant: 100),
            buildButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func configurePointStackView() {
        let pickerRowHeight: CGFloat = pickerView(distancePicker, rowHeightForComponent: 0)
        
        pointStackView.axis = .vertical
        pointStackView.spacing = 10
        pointStackView.alignment = .fill
        pointStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pointStackView)

        // Starting point
        startingPointLabel.text = "Starting point:"
        startingPointLabel.font = UIFont(name: "Avenir", size: 20)
        startingPointLabel.textColor = .white
        startingPointLabel.textAlignment = .center

        startingPointTextField.placeholder = "Starting address"
        startingPointTextField.font = UIFont(name: "Avenir", size: 18)
        startingPointTextField.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        startingPointTextField.textColor = .white
        startingPointTextField.layer.cornerRadius = 10
        startingPointTextField.textAlignment = .center
        startingPointTextField.isUserInteractionEnabled = false
        startingPointTextField.heightAnchor.constraint(equalToConstant: pickerRowHeight).isActive = true

        startingPointActionLabel.text = "Pick on map"
        startingPointActionLabel.font = UIFont(name: "Avenir", size: 16)
        startingPointActionLabel.textColor = .systemOrange
        startingPointActionLabel.textAlignment = .center
        startingPointActionLabel.isUserInteractionEnabled = true
        startingPointActionLabel.isHidden = true // hidden
        startingPointActionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(startingPointTapped)))

        currentLocationLabel.text = "Current location"
        currentLocationLabel.font = UIFont(name: "Avenir", size: 16)
        currentLocationLabel.textColor = .systemOrange
        currentLocationLabel.textAlignment = .center

        // Finishing point
        finishingPointLabel.text = "Finishing point:"
        finishingPointLabel.font = UIFont(name: "Avenir", size: 20)
        finishingPointLabel.textColor = .white
        finishingPointLabel.textAlignment = .center

        finishingPointTextField.placeholder = "Finishing address"
        finishingPointTextField.font = UIFont(name: "Avenir", size: 18)
        finishingPointTextField.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        finishingPointTextField.textColor = .white
        finishingPointTextField.layer.cornerRadius = 10
        finishingPointTextField.textAlignment = .center
        finishingPointTextField.isUserInteractionEnabled = false
        finishingPointTextField.heightAnchor.constraint(equalToConstant: pickerRowHeight).isActive = true

        finishingPointActionLabel.text = "Pick on map"
        finishingPointActionLabel.font = UIFont(name: "Avenir", size: 16)
        finishingPointActionLabel.textColor = .systemOrange
        finishingPointActionLabel.textAlignment = .center
        finishingPointActionLabel.isUserInteractionEnabled = true
        finishingPointActionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(finishingPointTapped)))

        // Add arranged subviews
        pointStackView.addArrangedSubview(startingPointLabel)
        pointStackView.addArrangedSubview(startingPointTextField)
        pointStackView.addArrangedSubview(startingPointActionLabel)
        pointStackView.addArrangedSubview(currentLocationLabel)
        pointStackView.addArrangedSubview(finishingPointLabel)
        pointStackView.addArrangedSubview(finishingPointTextField)
        pointStackView.addArrangedSubview(finishingPointActionLabel)
    }


    private func configurePickerStackView() {
        pickerStackView.axis = .vertical
        pickerStackView.spacing = 10
        pickerStackView.alignment = .fill
        pickerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pickerStackView)

        distanceLabel.text = "Choose desired distance:"
        distanceLabel.font = UIFont(name: "Avenir", size: 20)
        distanceLabel.textColor = .white
        distanceLabel.textAlignment = .center

        distancePicker.translatesAutoresizingMaskIntoConstraints = false
        distancePicker.dataSource = self
        distancePicker.delegate = self

        pickerStackView.addArrangedSubview(distanceLabel)
        pickerStackView.addArrangedSubview(distancePicker)
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
        distancePicker.dataSource = self
        distancePicker.delegate = self
    }

    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        // Do not start updating location here; wait for authorization callback
    }

    // CLLocationManagerDelegate method
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorizationStatus = manager.authorizationStatus
        
        // Ensure we're running this logic on a background thread
        DispatchQueue.global(qos: .background).async {
            // Check if location services are enabled in the background thread
            let locationServicesEnabled = CLLocationManager.locationServicesEnabled()
            
            // Return to the main thread to update the UI or proceed with location updates
            DispatchQueue.main.async {
                switch authorizationStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    if locationServicesEnabled {
                        self.locationManager.startUpdatingLocation()
                    } else {
                        print("Location services are disabled.")
                    }
                case .denied, .restricted:
                    print("Location services not authorized.")
                case .notDetermined:
                    print("Authorization not determined yet.")
                @unknown default:
                    print("Unknown authorization status.")
                }
            }
        }
    }


    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }

        // Set default starting and finishing point coordinates to the user's location
        if startingPointCoordinates == nil {
            startingPointCoordinates = currentLocation.coordinate
        }
        if finishingPointCoordinates == nil {
            finishingPointCoordinates = currentLocation.coordinate
        }

        // Optionally update the address fields if they are empty
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(currentLocation) { [weak self] placemarks, error in
            guard let self = self, error == nil, let placemark = placemarks?.first else { return }
            let address = [
                placemark.subThoroughfare,
                placemark.thoroughfare,
                placemark.locality
            ].compactMap { $0 }.joined(separator: ", ")

            if self.startingPointTextField.text?.isEmpty ?? true {
                self.startingPointTextField.text = address
            }
            if self.finishingPointTextField.text?.isEmpty ?? true {
                self.finishingPointTextField.text = address
            }
        }

        manager.stopUpdatingLocation() // Stop updating location to save battery
    }


    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    // MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return kilometers.count
    }

    // MARK: - UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(kilometers[row]) km"
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
/*
    @objc private func buildWorkoutButtonTapped() {
        guard let startingPoint = startingPointCoordinates, let finishingPoint = finishingPointCoordinates else {
            print("Starting or finishing point not set.")
            return
        }

        let selectedKm = kilometers[distancePicker.selectedRow(inComponent: 0)]
        let routeManager = RouteBuilderManager()
        routeManager.generateRoute(startingPoint: startingPoint, finishingPoint: finishingPoint, desiredDistance: selectedKm) { [weak self] routeCoordinates in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let routeCoordinates = routeCoordinates else {
                    print("Could not build route.")
                    // Optionally, display an alert to the user here
                    return
                }

                let builtRunVC = BuiltRunViewController()
                builtRunVC.route = routeCoordinates // Pass the route array to the new VC
                builtRunVC.modalPresentationStyle = .pageSheet
                self.present(builtRunVC, animated: true, completion: nil)
            }
        }
    }
*/
/*
    @objc private func buildWorkoutButtonTapped() {
        guard let startingPoint = startingPointCoordinates, let finishingPoint = finishingPointCoordinates else {
            print("Starting or finishing point not set.")
            return
        }

        let selectedKm = kilometers[distancePicker.selectedRow(inComponent: 0)]
        let routeManager = RouteBuilderManagerDemo()
        routeManager.generateRoute(startingPoint: startingPoint, finishingPoint: finishingPoint, distance: selectedKm) { [weak self] route, totalDistance in
            guard let self = self else { return }
            guard let route = route, let totalDistance = totalDistance else {
                print("Failed to generate route.")
                return
            }
            DispatchQueue.main.async {
                // Perform the segue and pass the data
                self.performSegue(withIdentifier: "ShowBuiltRouteSegue", sender: (route, totalDistance))
            }
        }
    }
 
 */
    @objc private func buildWorkoutButtonTapped() {
        guard let start = startingPointCoordinates, let end = finishingPointCoordinates else {
            print("Missing coordinates")
            return
        }

        let selectedKm = kilometers[distancePicker.selectedRow(inComponent: 0)]

        ExerunServerAPIManager.shared.buildRoute(start: start, end: end, distance: selectedKm) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let (route, distance)):
                    self.performSegue(withIdentifier: "ShowBuiltRouteSegue", sender: (route, distance))
                case .failure(let error):
                    print("Route building failed:", error)
                }
            }
        }
    }



    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowBuiltRouteSegue",
           let destinationVC = segue.destination as? BuiltRouteViewController,
           let data = sender as? ([CLLocationCoordinate2D], Double) {
            // Pass the route and total distance to BuiltRouteViewController
            destinationVC.route = data.0
            destinationVC.totalDistance = data.1
        }
    }


    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func startingPointTapped() {
        let mapVC = MapSelectionViewController()
        mapVC.delegate = self
        mapVC.selectionType = .startingPoint // Pass the selection type
        mapVC.modalPresentationStyle = .pageSheet
        present(mapVC, animated: true, completion: nil)
    }

    @objc private func finishingPointTapped() {
        let mapVC = MapSelectionViewController()
        mapVC.delegate = self
        mapVC.selectionType = .finishingPoint // Pass the selection type
        mapVC.modalPresentationStyle = .pageSheet
        present(mapVC, animated: true, completion: nil)
    }


}

// Extend MapSelectionDelegate to handle coordinate selection
extension NewBuildRunViewController: MapSelectionDelegate {
    func didSelectLocation(for type: SelectionType, location: CLLocationCoordinate2D, address: String?) {
        switch type {
        case .startingPoint:
            startingPointCoordinates = location
            startingPointTextField.text = address ?? "Selected Location"
        case .finishingPoint:
            finishingPointCoordinates = location
            finishingPointTextField.text = address ?? "Selected Location"
        }
    }
}
