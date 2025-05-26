//
//  NewCyclingViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//


import UIKit

class NewCyclingViewController: UIViewController {
    
    private var rainLayer: CAEmitterLayer?
    private var snowLayer: CAEmitterLayer?
    
    private var weatherImageView: UIImageView!
    private var labelsStackView: UIStackView!
    private var sunEventLabel: UILabel!
    private var temperatureLabel: UILabel!
    private var visibilityLabel: UILabel!
    private var humidityLabel: UILabel!
    private var windLabel: UILabel!
    private var pressureLabel: UILabel!
    private var precipitationLabel: UILabel!
    private var cyclingConditionLabel: UILabel!
    
    private var freeCyclingButton: UIButton!
    private var buildCyclingButton: UIButton!
    private var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchWeatherData()
    }
    
    private func fetchWeatherData() {
        WeatherLocationManager.shared.getWeatherData { [weak self] weatherData, error in
            guard let self = self, let weatherData = weatherData else {
                print("Failed to get weather data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.updateUI(with: weatherData)
        }
    }
    
    private func setupUI() {
        weatherImageView = UIImageView()
        weatherImageView.image = UIImage(named: "no_data_cycling")
        weatherImageView.contentMode = .scaleAspectFill
        weatherImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weatherImageView)
        
        freeCyclingButton = createStyledButton("Free Cycling", action: #selector(freeCyclingTapped))
        buildCyclingButton = createStyledButton("Build Cycling Route", action: #selector(buildCyclingTapped))
        
        backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemOrange, for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        view.addSubview(freeCyclingButton)
        view.addSubview(buildCyclingButton)
        
        temperatureLabel = createStyledLabel()
        visibilityLabel = createStyledLabel()
        humidityLabel = createStyledLabel()
        windLabel = createStyledLabel()
        pressureLabel = createStyledLabel()
        precipitationLabel = createStyledLabel()
        cyclingConditionLabel = createStyledLabel()
        sunEventLabel = createStyledLabel()
        
        labelsStackView = UIStackView(arrangedSubviews: [
            temperatureLabel, visibilityLabel, humidityLabel,
            windLabel, pressureLabel, precipitationLabel,
            cyclingConditionLabel, sunEventLabel
        ])
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .trailing
        labelsStackView.spacing = 5
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.isHidden = true
        view.addSubview(labelsStackView)
        
        setupConstraints()
    }
    
    private func createStyledButton(_ title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemOrange
        btn.titleLabel?.font = UIFont(name: "Avenir", size: 20)
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }
    
    private func createStyledLabel() -> UILabel {
        let lbl = PaddedLabel()
        lbl.font = UIFont(name: "Avenir", size: 15)
        lbl.textColor = .white
        lbl.textAlignment = .right
        lbl.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        lbl.layer.cornerRadius = 10
        lbl.clipsToBounds = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 1
        return lbl
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            weatherImageView.topAnchor.constraint(equalTo: view.topAnchor),
            weatherImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            weatherImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            weatherImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            buildCyclingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buildCyclingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buildCyclingButton.bottomAnchor.constraint(equalTo: freeCyclingButton.topAnchor, constant: -10),
            
            freeCyclingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            freeCyclingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            freeCyclingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            labelsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            labelsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    private func updateUI(with data: WeatherDataModel) {
        temperatureLabel.text = "Temperature: \(data.temperature ?? 0)°C"
        visibilityLabel.text = "Visibility: \(data.visibility ?? 0) km"
        humidityLabel.text = "Humidity: \(data.humidity ?? 0)%"
        windLabel.text = "Wind: \(data.windSpeed ?? 0) km/h"
        pressureLabel.text = "Pressure: \(data.pressure ?? 0) hPa"
        precipitationLabel.text = "Precipitation: \(data.precipitation ?? 0) mm/h"
        
        cyclingConditionLabel.text = determineCyclingCondition(
            temp: data.temperature ?? 0,
            visibility: data.visibility ?? 0,
            precipitation: data.precipitation ?? 0,
            weatherCode: data.weatherCode ?? 0
        )
        
        if let weatherCode = data.weatherCode {
            let imageName = determineCyclingImage(for: weatherCode, isDay: data.isDayTime)
            weatherImageView.image = UIImage(named: imageName)
            updateWeatherEffects(for: weatherCode, intensity: min((data.precipitation ?? 0) / 10.0, 1.0))
        }
        
        // Optional: handle sunrise/sunset
        if let sunRise = data.sunRise, let sunSet = data.sunSet {
            let formatter = ISO8601DateFormatter()
            if let rise = formatter.date(from: sunRise), let set = formatter.date(from: sunSet) {
                let fmt = DateFormatter(); fmt.dateFormat = "h:mm a"
                let now = Date()
                sunEventLabel.text = now < rise ? "Sunrise: \(fmt.string(from: rise))" :
                now < set ? "Sunset: \(fmt.string(from: set))" : "Night Time"
            }
        }
        
        if labelsStackView.isHidden {
            labelsStackView.isHidden = false
            labelsStackView.alpha = 0
            UIView.animate(withDuration: 0.4) {
                self.labelsStackView.alpha = 1
            }
        }
    }
    
    private func determineCyclingImage(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0: return isDay ? "day_clear_cycling" : "night_clear_cycling"
        case 1001, 1101, 1102: return isDay ? "day_cloudy_cycling" : "night_cloudy_cycling"
        case 4200, 4001, 4201: return isDay ? "day_rain_cycling" : "night_rain_cycling"
        case 5000, 5100, 5101: return isDay ? "day_snow_cycling" : "night_snow_cycling"
        default: return "no_data_cycling"
        }
    }
    
    private func determineCyclingCondition(temp: Double, visibility: Double, precipitation: Double, weatherCode: Int) -> String {
        if weatherCode >= 8000 { return "Thunderstorm, stay indoors!" }
        if precipitation > 5 { return "Heavy rain, unsafe for cycling!" }
        if temp < 0 { return "Freezing, wear warm gear!" }
        if visibility < 0.5 { return "Low visibility, be careful!" }
        return "Good weather for cycling!"
    }
    
    private func updateWeatherEffects(for code: Int, intensity: Double) {
        switch code {
        case 4000, 4200, 4001, 4201, 6000...6201, 7000...7102:
            addRainEffect(intensity: intensity)
            removeSnowEffect()
        case 5000...5101:
            addSnowEffect(intensity: intensity)
            removeRainEffect()
        default:
            removeRainEffect()
            removeSnowEffect()
        }
    }
    
    private func addRainEffect(intensity: Double) {
        removeRainEffect()
        let layer = CAEmitterLayer()
        layer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -10)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: view.bounds.width, height: 1)
        
        let cell = CAEmitterCell()
        cell.birthRate = Float(100 + intensity * 300)
        cell.lifetime = 4
        cell.velocity = CGFloat(200 + intensity * 300)
        cell.scale = CGFloat(0.02 + intensity * 0.03)
        cell.color = UIColor.white.cgColor
        cell.contents = drawRaindrop().cgImage
        
        layer.emitterCells = [cell]
        rainLayer = layer
        view.layer.addSublayer(layer)
    }
    
    private func addSnowEffect(intensity: Double) {
        removeSnowEffect()
        let layer = CAEmitterLayer()
        layer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -10)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: view.bounds.width, height: 1)
        
        let cell = CAEmitterCell()
        cell.birthRate = Float(30 + intensity * 50)
        cell.lifetime = 7
        cell.velocity = CGFloat(30 + intensity * 50)
        cell.scale = CGFloat(0.03 + intensity * 0.05)
        cell.color = UIColor.white.cgColor
        cell.contents = drawSnowflake().cgImage
        
        layer.emitterCells = [cell]
        snowLayer = layer
        view.layer.addSublayer(layer)
    }
    
    private func removeRainEffect() {
        rainLayer?.removeFromSuperlayer()
        rainLayer = nil
    }
    
    private func removeSnowEffect() {
        snowLayer?.removeFromSuperlayer()
        snowLayer = nil
    }
    
    private func drawRaindrop() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 2, height: 10), false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(2)
        ctx.move(to: .zero)
        ctx.addLine(to: CGPoint(x: 0, y: 10))
        ctx.strokePath()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func drawSnowflake() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 10, height: 10), false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: 10, height: 10))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    @objc private func freeCyclingTapped() {
        performSegue(withIdentifier: "FreeCyclingSegue", sender: self)
    }
    
    @objc private func buildCyclingTapped() {
        performSegue(withIdentifier: "BuildCyclingRouteSegue", sender: self)
    }
    
    @objc private func backTapped() {
        removeRainEffect()
        removeSnowEffect()
        dismiss(animated: true)
    }
    
    class PaddedLabel: UILabel {
        var textInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

        override func drawText(in rect: CGRect) {
            let insetsRect = rect.inset(by: textInsets)
            super.drawText(in: insetsRect)
        }

        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            return CGSize(width: size.width + textInsets.left + textInsets.right,
                          height: size.height + textInsets.top + textInsets.bottom)
        }
    }

}
