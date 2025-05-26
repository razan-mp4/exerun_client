//
//  WeatherLocationManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 20/11/2024.
//

import CoreLocation
import Foundation

class WeatherLocationManager: NSObject, CLLocationManagerDelegate {
    
    let apiKey = "2thRQRouRgeZdymET6t8sr244zL9cMG4"
    
    static let shared = WeatherLocationManager()
    
    private let locationManager = CLLocationManager()
    private var completionHandlers: [(WeatherDataModel?, Error?) -> Void] = []
    private var weatherData: WeatherDataModel?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func getWeatherData(completion: @escaping (WeatherDataModel?, Error?) -> Void) {
        if let weatherData = weatherData {
            print("Returning cached weather data: \(weatherData)")
            completion(weatherData, nil) // Return cached data
        } else {
            completionHandlers.append(completion) // Queue callbacks until data is available
            startLocationUpdates()
        }
    }
    
    private func fetchWeatherData(for coordinate: CLLocationCoordinate2D) {
        let weatherAPI = "https://api.tomorrow.io/v4/timelines?location=\(coordinate.latitude),\(coordinate.longitude)&fields=temperature,humidity,visibility,windSpeed,pressureSurfaceLevel,precipitationIntensity,weatherCode&timesteps=current&units=metric&apikey=\(apiKey)"
        
        guard let url = URL(string: weatherAPI) else {
            print("Invalid URL for weather API.")
            return
        }
        
        print("Fetching weather data from URL: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching weather data: \(error.localizedDescription)")
                self.notifyHandlers(weatherData: nil, error: error)
                return
            }
            
            guard let data = data else {
                print("No data received from weather API.")
                self.notifyHandlers(weatherData: nil, error: NSError(domain: "No data", code: 0))
                return
            }
            
            do {
                let weatherResponse = try JSONDecoder().decode(TomorrowWeatherData.self, from: data)
                print("Successfully decoded weather response: \(weatherResponse)")
                self.processWeatherResponse(weatherResponse, coordinate: coordinate)
            } catch {
                print("Error decoding weather data: \(error.localizedDescription)")
                self.notifyHandlers(weatherData: nil, error: error)
            }
        }.resume()
    }
    
    private func fetchSunriseSunset(for coordinate: CLLocationCoordinate2D, completion: @escaping (Bool?, String?, String?, Error?) -> Void) {
        let sunriseSunsetAPI = "https://api.sunrise-sunset.org/json?lat=\(coordinate.latitude)&lng=\(coordinate.longitude)&formatted=0"
        
        guard let url = URL(string: sunriseSunsetAPI) else {
            print("Invalid URL for sunrise/sunset API.")
            return
        }
        
        print("Fetching sunrise/sunset data from URL: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching sunrise/sunset data: \(error.localizedDescription)")
                completion(nil, nil, nil, error)
                return
            }
            
            guard let data = data else {
                print("No data received from sunrise/sunset API.")
                completion(nil, nil, nil, NSError(domain: "No data", code: 0))
                return
            }
            
            do {
                let sunriseSunsetResponse = try JSONDecoder().decode(SunriseSunsetResponse.self, from: data)
                let sunrise = sunriseSunsetResponse.results.sunrise
                let sunset = sunriseSunsetResponse.results.sunset
                
                let isDay = self.determineDayTime(sunrise: sunrise, sunset: sunset)
                completion(isDay, sunrise, sunset, nil)
            } catch {
                print("Error decoding sunrise/sunset data: \(error.localizedDescription)")
                completion(nil, nil, nil, error)
            }
        }.resume()
    }
    
    private func processWeatherResponse(_ weatherResponse: TomorrowWeatherData, coordinate: CLLocationCoordinate2D) {
        fetchSunriseSunset(for: coordinate) { isDayTime, sunrise, sunset, error in
            guard let isDayTime = isDayTime, let sunrise = sunrise, let sunset = sunset, error == nil else {
                print("Error determining day/night time: \(error?.localizedDescription ?? "Unknown error")")
                self.notifyHandlers(weatherData: nil, error: error)
                return
            }
            
            let currentWeather = weatherResponse.data.timelines.first?.intervals.first?.values
            print("Current weather values: \(String(describing: currentWeather))")
            
            self.weatherData = WeatherDataModel(
                temperature: currentWeather?.temperature,
                humidity: currentWeather?.humidity,
                visibility: currentWeather?.visibility,
                windSpeed: currentWeather?.windSpeed,
                pressure: currentWeather?.pressureSurfaceLevel,
                precipitation: currentWeather?.precipitationIntensity,
                weatherCode: currentWeather?.weatherCode,
                isDayTime: isDayTime,
                sunSet: sunset,
                sunRise: sunrise
            )
            
            print("Processed weather data model: \(String(describing: self.weatherData))")
            
            self.notifyHandlers(weatherData: self.weatherData, error: nil)
        }
    }
    
    private func notifyHandlers(weatherData: WeatherDataModel?, error: Error?) {
        DispatchQueue.main.async {
            if let weatherData = weatherData {
                print("Notifying handlers with weather data: \(weatherData)")
            } else if let error = error {
                print("Notifying handlers with error: \(error.localizedDescription)")
            }
            self.completionHandlers.forEach { $0(weatherData, error) }
            self.completionHandlers.removeAll()
        }
    }
    
    private func determineDayTime(sunrise: String, sunset: String) -> Bool {
        guard let sunriseDate = adjustToLocalTime(utcTime: sunrise),
              let sunsetDate = adjustToLocalTime(utcTime: sunset) else {
            print("Failed to determine day/night time: defaulting to daytime.")
            return true
        }

        let currentTime = Date()
        return currentTime >= sunriseDate && currentTime <= sunsetDate
    }
    
    private func adjustToLocalTime(utcTime: String) -> Date? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.date(from: utcTime)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("Failed to get the user's location.")
            return
        }
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        locationManager.stopUpdatingLocation()
        fetchWeatherData(for: location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        notifyHandlers(weatherData: nil, error: error)
    }
}
