//
//  NewBuildCyclingViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//


import UIKit
import CoreLocation

enum CyclingSelectionType {
    case startingPoint
    case finishingPoint
}

final class NewBuildCyclingViewController: UIViewController,
                                          UIPickerViewDataSource,
                                          UIPickerViewDelegate,
                                          UITextFieldDelegate,
                                          CLLocationManagerDelegate {

    // MARK: - Properties ----------------------------------------------------

    private var currentSelectionType: CyclingSelectionType?

    private var startingPointCoordinates: CLLocationCoordinate2D?
    private var finishingPointCoordinates: CLLocationCoordinate2D?

    //  UI ------------------------------------------------------------------
    private let titleLabel             = UILabel()
    private let distanceLabel          = UILabel()
    private let distancePicker         = UIPickerView()
    private let startingPointLabel     = UILabel()
    private let startingPointTextField = UITextField()
    private let startingPointActionLbl = UILabel()
    private let currentLocationLabel   = UILabel()
    private let finishingPointLabel    = UILabel()
    private let finishingPointTextField = UITextField()
    private let finishingPointActionLbl = UILabel()
    private let buildButton            = UIButton(type: .system)
    private let backButton             = UIButton(type: .system)

    private let pointStack  = UIStackView()
    private let pickerStack = UIStackView()
    private let mainStack   = UIStackView()

    //  Data ----------------------------------------------------------------
    private let kilometers      = Array(1...1000)   // 1 km-1 000 km
    private let locationManager = CLLocationManager()

    // MARK: - Lifecycle ----------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBackButton()
        distancePicker.dataSource = self
        distancePicker.delegate   = self

        // Default picker row ⇒ 10 km
        if let defaultRow = kilometers.firstIndex(of: 10) {
            distancePicker.selectRow(defaultRow, inComponent: 0, animated: false)
        }

        setupLocationServices()
        overrideUserInterfaceStyle = .dark
    }

    // MARK: - UI Setup ------------------------------------------------------

    private func setupUI() {
        // ---- background ---------------------------------------------------
        let bg = UIImageView(image: UIImage(named: "no_data_cycling"))
        bg.contentMode = .scaleAspectFill
        bg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bg)

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: view.topAnchor),
            bg.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            overlay.topAnchor.constraint(equalTo: bg.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: bg.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: bg.trailingAnchor)
        ])

        // ---- Title --------------------------------------------------------
        titleLabel.text          = "Build Your Ride"
        titleLabel.font          = UIFont(name: "Avenir", size: 24)
        titleLabel.textColor     = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // ---- Point Stack (start/finish) -----------------------------------
        configurePointStack()

        // ---- Picker stack (distance) --------------------------------------
        configurePickerStack()

        // ---- Main vertical stack ------------------------------------------
        mainStack.axis = .vertical
        mainStack.spacing = 30
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(pointStack)
        mainStack.addArrangedSubview(pickerStack)
        view.addSubview(mainStack)

        // ---- Build button --------------------------------------------------
        buildButton.setTitle("Build", for: .normal)
        buildButton.setTitleColor(.white, for: .normal)
        buildButton.backgroundColor = .systemOrange
        buildButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        buildButton.layer.cornerRadius = 20
        buildButton.translatesAutoresizingMaskIntoConstraints = false
        buildButton.addTarget(self, action: #selector(buildTapped), for: .touchUpInside)
        view.addSubview(buildButton)

        // ---- Constraints ---------------------------------------------------
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            buildButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buildButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            buildButton.widthAnchor.constraint(equalToConstant: 100),
            buildButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func configurePointStack() {
        // common metrics
        let rowHeight: CGFloat = pickerView(distancePicker, rowHeightForComponent: 0)

        pointStack.axis = .vertical
        pointStack.spacing = 10
        pointStack.alignment = .fill
        pointStack.translatesAutoresizingMaskIntoConstraints = false

        // --- starting ------------------------------------------------------
        startingPointLabel.applyTitle("Starting point:")
        startingPointTextField.applyInputPlaceholder("Starting address",
                                                     height: rowHeight)
        startingPointActionLbl.applyAction("Pick on map",
                                           target: self,
                                           selector: #selector(startingPointTap))
        startingPointActionLbl.isHidden = true

        currentLocationLabel.applyAction("Current location",
                                         target: nil,
                                         selector: nil)

        // --- finishing -----------------------------------------------------
        finishingPointLabel.applyTitle("Finishing point:")
        finishingPointTextField.applyInputPlaceholder("Finishing address",
                                                      height: rowHeight)
        finishingPointActionLbl.applyAction("Pick on map",
                                            target: self,
                                            selector: #selector(finishingPointTap))

        // --- bundle into stack --------------------------------------------
        [startingPointLabel,
         startingPointTextField,
         startingPointActionLbl,
         currentLocationLabel,
         finishingPointLabel,
         finishingPointTextField,
         finishingPointActionLbl].forEach { pointStack.addArrangedSubview($0) }
    }

    private func configurePickerStack() {
        pickerStack.axis = .vertical
        pickerStack.spacing = 10
        pickerStack.alignment = .fill
        pickerStack.translatesAutoresizingMaskIntoConstraints = false

        distanceLabel.text          = "Choose desired distance:"
        distanceLabel.font          = UIFont(name: "Avenir", size: 20)
        distanceLabel.textColor     = .white
        distanceLabel.textAlignment = .center

        distancePicker.translatesAutoresizingMaskIntoConstraints = false

        pickerStack.addArrangedSubview(distanceLabel)
        pickerStack.addArrangedSubview(distancePicker)
    }

    private func setupBackButton() {
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemOrange, for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }

    // MARK: - Location ------------------------------------------------------

    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if CLLocationManager.locationServicesEnabled() { manager.startUpdatingLocation() }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {

        guard let loc = locations.last else { return }

        if startingPointCoordinates == nil { startingPointCoordinates  = loc.coordinate }
        if finishingPointCoordinates == nil { finishingPointCoordinates = loc.coordinate }

        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            guard let self, let first = placemarks?.first else { return }
            let address = [first.subThoroughfare,
                           first.thoroughfare,
                           first.locality]
                .compactMap { $0 }
                .joined(separator: ", ")

            if self.startingPointTextField.text?.isEmpty ?? true {
                self.startingPointTextField.text = address
            }
            if self.finishingPointTextField.text?.isEmpty ?? true {
                self.finishingPointTextField.text = address
            }
        }
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }

    // MARK: - UIPickerView --------------------------------------------------

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        kilometers.count
    }
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        "\(kilometers[row]) km"
    }
    func pickerView(_ pickerView: UIPickerView,
                    rowHeightForComponent component: Int) -> CGFloat { 40 }

    // MARK: - Actions -------------------------------------------------------

    @objc private func backTapped()  { dismiss(animated: true) }

    @objc private func startingPointTap()  {
        presentMap(for: .startingPoint)
    }
    @objc private func finishingPointTap() {
        presentMap(for: .finishingPoint)
    }

    private func presentMap(for type: CyclingSelectionType) {
        let mapVC = MapSelectionViewController()
        mapVC.delegate       = self
        mapVC.selectionType  = (type == .startingPoint) ? .startingPoint : .finishingPoint
        mapVC.modalPresentationStyle = .pageSheet
        present(mapVC, animated: true)
    }

    @objc private func buildTapped() {
        guard let start = startingPointCoordinates,
              let end   = finishingPointCoordinates else {
            print("Missing coordinates")
            return
        }

        let km = kilometers[distancePicker.selectedRow(inComponent: 0)]

        ExerunServerAPIManager.shared.buildRoute(start: start, end: end, distance: km) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let (route, totalDistance)):
                    self.performSegue(withIdentifier: "ShowBuiltCyclingRouteSegue",
                                      sender: (route, totalDistance))
                case .failure(let err):
                    print("Route build failed:", err.localizedDescription)
                }
            }
        }
    }

    // MARK: - Navigation ----------------------------------------------------

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowBuiltCyclingRouteSegue",
           let dest = segue.destination as? BuiltCyclingRouteViewController,   // ✅ FIX
           let data = sender as? ([CLLocationCoordinate2D], Double) {

            dest.route         = data.0
            dest.totalDistance = data.1
        }
    }

}

// MARK: - MapSelectionDelegate ---------------------------------------------

extension NewBuildCyclingViewController: MapSelectionDelegate {
    func didSelectLocation(for type: SelectionType,
                           location: CLLocationCoordinate2D,
                           address: String?) {

        switch type {
        case .startingPoint:
            startingPointCoordinates  = location
            startingPointTextField.text = address ?? "Selected location"
        case .finishingPoint:
            finishingPointCoordinates = location
            finishingPointTextField.text = address ?? "Selected location"
        }
    }
}

// MARK: - UILabel / UITextField helpers ------------------------------------

private extension UILabel {
    func applyTitle(_ txt: String) {
        text          = txt
        font          = UIFont(name: "Avenir", size: 20)
        textColor     = .white
        textAlignment = .center
    }
    func applyAction(_ txt: String,
                     target: AnyObject?,
                     selector: Selector?) {
        text          = txt
        font          = UIFont(name: "Avenir", size: 16)
        textColor     = .systemOrange
        textAlignment = .center
        isUserInteractionEnabled = selector != nil
        if let sel = selector, let tgt = target {
            addGestureRecognizer(UITapGestureRecognizer(target: tgt,
                                                         action: sel))
        }
    }
}

private extension UITextField {
    func applyInputPlaceholder(_ placeholderTxt: String, height: CGFloat) {
        placeholder     = placeholderTxt
        font            = UIFont(name: "Avenir", size: 18)
        backgroundColor = UIColor.white.withAlphaComponent(0.3)
        textColor       = .white
        layer.cornerRadius = 10
        textAlignment   = .center
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
