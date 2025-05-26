//
//  HikeWalkViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 25/1/2025.
//

import UIKit
import CoreLocation

class NewHikeWalkViewController: UIViewController {
    
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
    private var hikingConditionLabel: UILabel!
    
    private var startHikeButton: UIButton!
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
        // Full-Screen Weather Image View
        weatherImageView = UIImageView()
        weatherImageView.image = UIImage(named: "no_data_hiking") // Placeholder image
        weatherImageView.contentMode = .scaleAspectFill
        weatherImageView.translatesAutoresizingMaskIntoConstraints = false
        weatherImageView.clipsToBounds = true
        view.addSubview(weatherImageView)
        
        // Start Hike Button
        startHikeButton = createStyledButton(withTitle: "Start Hike", action: #selector(startHikeButtonTapped))
        
        
        // Back Button
        backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemOrange, for: .normal)
        backButton.titleLabel?.font = UIFont(name: "Avenir-Light", size: 20)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Add Buttons to View
        view.addSubview(startHikeButton)
        
        // Create and Configure Labels
        temperatureLabel = createStyledLabel()
        visibilityLabel = createStyledLabel()
        humidityLabel = createStyledLabel()
        windLabel = createStyledLabel()
        pressureLabel = createStyledLabel()
        precipitationLabel = createStyledLabel()
        hikingConditionLabel = createStyledLabel()
        
        // Create Sun Event Label
        sunEventLabel = createStyledLabel()
        sunEventLabel.text = "" // Initially empty
        
        // Stack View for Labels
        labelsStackView = UIStackView(arrangedSubviews: [
            temperatureLabel,
            visibilityLabel,
            humidityLabel,
            windLabel,
            pressureLabel,
            precipitationLabel,
            hikingConditionLabel
        ])
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .trailing
        labelsStackView.distribution = .equalSpacing
        labelsStackView.spacing = 5
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.isHidden = true // Hide labels initially
        view.addSubview(labelsStackView)
        labelsStackView.insertArrangedSubview(sunEventLabel, at: labelsStackView.arrangedSubviews.count - 1)
        
        // Setup Constraints
        setupConstraints()
    }
    
    private func createStyledButton(withTitle title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemOrange
        button.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createStyledLabel() -> UILabel {
        let label = PaddedLabel()
        label.font = UIFont(name: "Avenir", size: 15)
        label.textColor = .white
        label.textAlignment = .right
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Full-Screen Weather Image
            weatherImageView.topAnchor.constraint(equalTo: view.topAnchor),
            weatherImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            weatherImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            weatherImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Start Hike Button
            startHikeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startHikeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            startHikeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Stack View for Labels
            labelsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            labelsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    private func updateUI(with weatherData: WeatherDataModel) {
        temperatureLabel.text = "Temperature: \(weatherData.temperature ?? 0)°C"
        visibilityLabel.text = "Visibility: \(weatherData.visibility ?? 0) km"
        humidityLabel.text = "Humidity: \(weatherData.humidity ?? 0)%"
        windLabel.text = "Wind Speed: \(weatherData.windSpeed ?? 0) km/h"
        pressureLabel.text = "Pressure: \(weatherData.pressure ?? 0) hPa"
        precipitationLabel.text = "Precipitation: \(weatherData.precipitation ?? 0) mm/h"
        
        // Update Sun Event Label
        if let sunRise = weatherData.sunRise, let sunSet = weatherData.sunSet {
            let currentTime = Date()
            let dateFormatter = ISO8601DateFormatter()
            
            if let sunriseTime = dateFormatter.date(from: sunRise),
               let sunsetTime = dateFormatter.date(from: sunSet) {
                if currentTime >= sunriseTime && currentTime <= sunsetTime {
                    // Daytime
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "h:mm a"
                    let sunsetString = timeFormatter.string(from: sunsetTime)
                    sunEventLabel.text = "Sunsets at \(sunsetString)"
                } else {
                    // Nighttime
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "h:mm a"
                    let sunriseString = timeFormatter.string(from: sunriseTime)
                    sunEventLabel.text = "Sunrises at \(sunriseString)"
                }
            } else {
                sunEventLabel.text = "Sunrise/Sunset data unavailable"
            }
        }

        
        if let weatherCode = weatherData.weatherCode {
            let imageName = determineWeatherImage(for: weatherCode, isDayTime: weatherData.isDayTime)
            weatherImageView.image = UIImage(named: imageName)
        } else {
            weatherImageView.image = UIImage(named: "no_data_hiking")
        }
        
        hikingConditionLabel.text = determineHikingCondition(
            temp: weatherData.temperature ?? 0,
            visibility: weatherData.visibility ?? 0,
            precipitation: weatherData.precipitation ?? 0,
            weatherCode: weatherData.weatherCode ?? 0
        )
        
        // Add rain or snow effect based on weather
        if let weatherCode = weatherData.weatherCode {
            let precipitationIntensity = weatherData.precipitation ?? 0
            let normalizedIntensity = min(precipitationIntensity / 10.0, 1.0) // Normalize to 0.0 - 1.0
            updateWeatherEffects(for: weatherCode, intensity: normalizedIntensity)
        } else {
            removeRainEffect()
            removeSnowEffect()
        }
        
        // Show labels with animation
        if labelsStackView.isHidden {
            labelsStackView.isHidden = false
            labelsStackView.alpha = 0
            UIView.animate(withDuration: 0.5) {
                self.labelsStackView.alpha = 1
            }
        }
    }
    
    private func determineWeatherImage(for weatherCode: Int, isDayTime: Bool) -> String {
        switch weatherCode {
        case 0: return isDayTime ? "day_clear_hiking" : "night_clear_hiking" // Clear
        case 1001: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Cloudy
        case 1100: return isDayTime ? "day_clear_hiking" : "night_clear_hiking" // Mostly Clear
        case 1101: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Partly Cloudy
        case 1102: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Mostly Cloudy
        case 2000: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Fog
        case 2100: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Light Fog
        case 3000: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Light Wind
        case 3001: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Wind
        case 3002: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Strong Wind
        case 4000: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Drizzle
        case 4200: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Light Rain
        case 4001: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Rain
        case 4201: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Heavy Rain
        case 5000: return isDayTime ? "day_snow_hiking" : "night_snow_hiking" // Snow
        case 5001: return isDayTime ? "day_snow_hiking" : "night_snow_hiking" // Flurries
        case 5100: return isDayTime ? "day_snow_hiking" : "night_snow_hiking" // Light Snow
        case 5101: return isDayTime ? "day_snow_hiking" : "night_snow_hiking" // Heavy Snow
        case 6000: return isDayTime ? "day_cloudy_hiking" : "night_cloudy_hiking" // Freezing Drizzle
        case 6001: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Freezing Rain
        case 6200: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Light Freezing Rain
        case 6201: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Heavy Freezing Rain
        case 7000: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Ice Pellets
        case 7101: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Heavy Ice Pellets
        case 7102: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Light Ice Pellets
        case 8000: return isDayTime ? "day_rain_hiking" : "night_rain_hiking" // Thunderstorm
        default: return "no_data_hiking" // Default image
        }
    }
    
    private func determineHikingCondition(temp: Double, visibility: Double, precipitation: Double, weatherCode: Int) -> String {
        switch weatherCode {
        case 4000, 4200, 4001, 4201: // Drizzle, Light Rain, Rain, Heavy Rain
            return "Rainy conditions, hike/walk cautiously!"
        case 5000, 5100, 5101: // Snow, Light Snow, Heavy Snow
            return "Snowy conditions, be cautious!"
        case 6000, 6200, 6001, 6201: // Freezing Drizzle, Light Freezing Rain, Freezing Rain, Heavy Freezing Rain
            return "Freezing rain conditions, very slippery!"
        case 7000, 7102, 7101: // Ice Pellets, Light Ice Pellets, Heavy Ice Pellets
            return "Icy conditions, be extremely cautious!"
        case 8000: // Thunderstorm
            return "Thunderstorm, avoid hiking/walking!"
        default: // Clear or other unhandled conditions
            if temp > 30 {
                return "It's too hot for hiking!"
            } else if temp < 0 {
                return "It's freezing outside!"
            } else if visibility < 0.5 {
                return "Low visibility, be careful!"
            } else {
                return "Good weather for a hike!"
            }
        }
    }
    
    @objc private func startHikeButtonTapped() {
        performSegue(withIdentifier: "StartHikeWalkSegue", sender: self)
    }
    
    
    @objc private func backButtonTapped() {
        removeRainEffect()
        removeSnowEffect()
        dismiss(animated: true, completion: nil)
    }
    
    private func updateWeatherEffects(for weatherCode: Int, intensity: Double) {
        switch weatherCode {
        case 0: // Clear
            removeRainEffect()
            removeSnowEffect()
            
        case 1001: // Cloudy
            removeRainEffect()
            removeSnowEffect()
            
        case 1100, 1101, 1102: // Mostly Clear, Partly Cloudy, Mostly Cloudy
            removeRainEffect()
            removeSnowEffect()
            
        case 2000, 2100: // Fog, Light Fog
            removeRainEffect()
            removeSnowEffect()
            
        case 3000, 3001, 3002: // Light Wind, Wind, Strong Wind
            removeRainEffect()
            removeSnowEffect()
            
        case 4000: // Drizzle
            addRainEffect(intensity: 0.2)
            removeSnowEffect()
            
        case 4200: // Light Rain
            addRainEffect(intensity: 0.5)
            removeSnowEffect()
            
        case 4001: // Rain
            addRainEffect(intensity: 0.7)
            removeSnowEffect()
            
        case 4201: // Heavy Rain
            addRainEffect(intensity: 1.0)
            removeSnowEffect()
            
        case 5000: // Snow
            addSnowEffect(intensity: 0.5)
            removeRainEffect()
            
        case 5100: // Light Snow
            addSnowEffect(intensity: 0.3)
            removeRainEffect()
            
        case 5101: // Heavy Snow
            addSnowEffect(intensity: 1.0)
            removeRainEffect()
            
        case 6000: // Freezing Drizzle
            addRainEffect(intensity: 0.3)
            removeSnowEffect()
            
        case 6200: // Light Freezing Rain
            addRainEffect(intensity: 0.5)
            removeSnowEffect()
            
        case 6001: // Freezing Rain
            addRainEffect(intensity: 0.7)
            removeSnowEffect()
            
        case 6201: // Heavy Freezing Rain
            addRainEffect(intensity: 1.0)
            removeSnowEffect()
            
        case 7000: // Ice Pellets
            addSnowEffect(intensity: 0.5)
            removeRainEffect()
            
        case 7102: // Light Ice Pellets
            addSnowEffect(intensity: 0.3)
            removeRainEffect()
            
        case 7101: // Heavy Ice Pellets
            addSnowEffect(intensity: 1.0)
            removeRainEffect()
            
        case 8000: // Thunderstorm
            addRainEffect(intensity: 1.0)
            removeSnowEffect()
            
        default: // Unhandled or no precipitation
            removeRainEffect()
            removeSnowEffect()
        }
    }
    
    private func addRainEffect(intensity: Double) {
        removeRainEffect() // Remove existing effect to avoid layering
        let rainLayer = CAEmitterLayer()
        rainLayer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -10)
        rainLayer.emitterSize = CGSize(width: view.bounds.width, height: 1)
        rainLayer.emitterShape = .line

        let rainCell = CAEmitterCell()
        rainCell.birthRate = Float(CGFloat(100 + (intensity * 200))) // Adjust based on intensity
        rainCell.lifetime = 4.0
        rainCell.velocity = CGFloat(200 + (intensity * 300)) // Faster rain for higher intensity
        rainCell.velocityRange = 50
        rainCell.yAcceleration = 200
        rainCell.scale = CGFloat(0.02 + (intensity * 0.03)) // Larger drops for higher intensity
        rainCell.scaleRange = 0.01
        rainCell.color = UIColor.white.cgColor
        rainCell.contents = drawRaindrop().cgImage

        rainLayer.emitterCells = [rainCell]
        self.rainLayer = rainLayer
        view.layer.addSublayer(rainLayer)
    }

    private func addSnowEffect(intensity: Double) {
        removeSnowEffect() // Remove existing effect to avoid layering
        let snowLayer = CAEmitterLayer()
        snowLayer.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -10)
        snowLayer.emitterSize = CGSize(width: view.bounds.width, height: 1)
        snowLayer.emitterShape = .line

        let snowCell = CAEmitterCell()
        snowCell.birthRate = Float(CGFloat(20 + (intensity * 50))) // Adjust based on intensity
        snowCell.lifetime = 7.0
        snowCell.velocity = CGFloat(30 + (intensity * 50)) // Faster snow for higher intensity
        snowCell.velocityRange = 20
        snowCell.yAcceleration = 30
        snowCell.scale = CGFloat(0.03 + (intensity * 0.05)) // Larger flakes for higher intensity
        snowCell.scaleRange = 0.02
        snowCell.color = UIColor.white.cgColor
        snowCell.contents = drawSnowflake().cgImage

        snowLayer.emitterCells = [snowCell]
        self.snowLayer = snowLayer
        view.layer.addSublayer(snowLayer)
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
        let size = CGSize(width: 2, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.white.cgColor)
        context.move(to: CGPoint(x: size.width / 2, y: 0))
        context.addLine(to: CGPoint(x: size.width / 2, y: size.height))
        context.strokePath()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    private func drawSnowflake() -> UIImage {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.white.cgColor)
        let circleRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.fillEllipse(in: circleRect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
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
