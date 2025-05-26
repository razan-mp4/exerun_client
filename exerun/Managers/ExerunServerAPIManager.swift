//
//  APIService.swift
//  exerun
//
//  Created by Nazar Odemchuk on 14/4/2025.
//

import Foundation
import CoreLocation

/// Handles all network interactions with the Exerun backend
final class ExerunServerAPIManager {
    static let shared = ExerunServerAPIManager()
    private init() {}

    // ──────────────────────────────────────────────────────────────────────────
    private let baseURL = URL(string: "http://192.168.0.103:8000")!
    private var authToken: String? { KeychainManager.shared.loadToken() }

    // MARK: – OAuth (Google) ──────────────────────────────────────────────────
    func oauthLogin(idToken: String,
                    provider: String,
                    completion: @escaping (Result<String,Error>) -> Void) {

        let url  = baseURL.appendingPathComponent("/auth/oauth")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["token": idToken, "provider": provider])

        URLSession.shared.dataTask(with: req) { data, _, err in
            self.handleTokenResponse(data: data, error: err, completion: completion)
        }.resume()
    }

    // MARK: – Email / Password ────────────────────────────────────────────────
    func emailLogin(email: String,
                    password: String,
                    completion: @escaping (Result<String,Error>) -> Void) {

        let url  = baseURL.appendingPathComponent("/auth/login")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["email": email, "password": password])

        URLSession.shared.dataTask(with: req) { data, _, err in
            self.handleTokenResponse(data: data, error: err, completion: completion)
        }.resume()
    }

    func register(email: String,
                  password: String,
                  name: String,
                  surname: String,
                  completion: @escaping (Result<String,Error>) -> Void) {

        let url  = baseURL.appendingPathComponent("/auth/register")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String:String] = [
            "email"   : email,
            "password": password,
            "name"    : name,
            "surname" : surname
        ]
        req.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: req) { data, _, err in
            self.handleTokenResponse(data: data, error: err, completion: completion)
        }.resume()
    }

    // MARK: – Logout ──────────────────────────────────────────────────────────
    /// Clears the JWT in the Keychain once the server responds 200 OK.
    func logout(completion: @escaping (Result<Void,Error>) -> Void) {
        let logoutPath = "/auth/logout"

        let url  = baseURL.appendingPathComponent(logoutPath)
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"

        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: req) { _, response, error in
            if let error = error { completion(.failure(error)); return }

            guard let http = response as? HTTPURLResponse,
                  200..<300 ~= http.statusCode else {
                completion(.failure(APIError.badStatus)); return
            }
            // Remove the saved JWT
            KeychainManager.shared.deleteToken()
            completion(.success(()))
        }.resume()
    }

    // MARK: – Route generation ───────────────────────────────────
    func buildRoute(start: CLLocationCoordinate2D,
                    end:   CLLocationCoordinate2D,
                    distance: Int,
                    completion: @escaping (Result<([CLLocationCoordinate2D],Double),Error>) -> Void) {

        let url  = baseURL.appendingPathComponent("/routes/generate")
        var req  = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload = RouteRequest(
            startingPoint : .init(latitude: start.latitude, longitude: start.longitude),
            finishingPoint: .init(latitude: end.latitude,   longitude: end.longitude),
            distance: distance)

        req.httpBody = try? JSONEncoder().encode(payload)

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(APIError.noData)); return }

            do {
                let resp   = try JSONDecoder().decode(RouteResponse.self, from: data)
                let coords = resp.route.map { CLLocationCoordinate2D(latitude: $0.latitude,
                                                                     longitude: $0.longitude) }
                completion(.success((coords, resp.distance_m)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: – Update current user's profile (PUT /profiles/me)
    func updateProfile(data: ProfileUpdateRequest, completion: @escaping (Result<ProfileResponse, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(APIError.noToken)); return
        }

        let url = baseURL.appendingPathComponent("/profiles/me")
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONEncoder().encode(data)

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let profile = try JSONDecoder().decode(ProfileResponse.self, from: data)
                completion(.success(profile))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: – Fetch current user info (GET /users/me)
    func getCurrentUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(APIError.noToken)); return
        }

        var req = URLRequest(url: baseURL.appendingPathComponent("/users/me"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }

            guard let data = data else {
                completion(.failure(APIError.noData)); return
            }

            do {
                let decoder = JSONDecoder()

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = .current

                decoder.dateDecodingStrategy = .formatted(formatter)

                let user = try decoder.decode(User.self, from: data)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


    // MARK: – (POST /profiles/me/upload-profile-picture)
    func uploadProfileImage(_ imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(APIError.noToken))
            return
        }

        let url = baseURL.appendingPathComponent("/profiles/me/upload-profile-picture")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let profilePictureURL = json["profile_picture_url"] as? String {
                    completion(.success(profilePictureURL))
                } else {
                    completion(.failure(APIError.badStatus))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: – (GET /profiles/me)
    func getCurrentProfile(completion: @escaping (Result<ProfileResponse, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(APIError.noToken)); return
        }

        var req = URLRequest(url: baseURL.appendingPathComponent("/profiles/me"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }

            guard let data = data else {
                completion(.failure(APIError.noData)); return
            }

            do {
                let profile = try JSONDecoder().decode(ProfileResponse.self, from: data)
                completion(.success(profile))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: – Update current user info (PUT /users/me)
    func updateUser(name: String, surname: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(APIError.noToken))
            return
        }

        let url = baseURL.appendingPathComponent("/users/me")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let payload: [String: String] = [
            "name": name,
            "surname": surname
        ]
        request.httpBody = try? JSONEncoder().encode(payload)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            do {
                let decoder = JSONDecoder()

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = .current
                decoder.dateDecodingStrategy = .formatted(formatter)

                let user = try decoder.decode(User.self, from: data)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Download profile picture and save it locally
    func downloadProfilePicture(urlString: String) {
        let fullURL = baseURL.appendingPathComponent(urlString)
        
        URLSession.shared.dataTask(with: fullURL) { data, _, error in
            if let error = error {
                print("❌ Failed to download profile picture:", error)
                return
            }
            guard let data = data else {
                print("❌ No data when downloading profile picture")
                return
            }
            
            DispatchQueue.main.async {
                ProfileStorage.shared.saveProfileImage(data)
                print("✅ Profile picture downloaded and saved locally")
            }
        }.resume()
    }
    
    // MARK: – Workouts › POST /workouts
    func createWorkout(_ payload: WorkoutUpload,
                       completion: @escaping(Result<WorkoutCreateResponse,Error>)->Void)
    {
        guard let token = authToken else {
            completion(.failure(APIError.noToken)); return
        }

        var req = URLRequest(url: baseURL.appendingPathComponent("/workouts/"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        req.httpBody = try? enc.encode(payload)

        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err { completion(.failure(err)); return }
            guard let data else { completion(.failure(APIError.noData)); return }

            do {
                let resp = try JSONDecoder().decode(WorkoutCreateResponse.self, from: data)
                completion(.success(resp))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }



    func uploadWorkoutImage(remoteID: String,
                            imageData: Data,
                            _ completion: @escaping(Result<String,Error>)->Void) {

        guard let token = authToken else { completion(.failure(APIError.noToken)); return }

        var req = URLRequest(
            url: baseURL.appendingPathComponent("/workouts/\(remoteID)/image"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)",
                     forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"w.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")
        req.httpBody = body


        URLSession.shared.dataTask(with: req) { data,_,err in
            if let err = err { completion(.failure(err)); return }
            guard let d = data else { completion(.failure(APIError.noData)); return }
            do {
                struct R: Decodable { let image_url: String }
                let url = try JSONDecoder().decode(R.self, from: d).image_url
                completion(.success(url))
            } catch { completion(.failure(error)) }
        }.resume()
    }

    // MARK: – Workouts list (GET /workouts/me) ───────────────────────────────
    func listMyWorkouts(
        since: Date?,
        completion: @escaping (Result<[WorkoutResponse],Error>) -> Void
    ) {
        // 0️⃣ – Auth
        guard let token = authToken else {
            completion(.failure(APIError.noToken)); return
        }

        // 1️⃣ – Build URL   /workouts/me?since=ISO-STRING
        var comps = URLComponents(url: baseURL.appendingPathComponent("/workouts/me"),
                                  resolvingAgainstBaseURL: false)!
        if let s = since {
            let iso = ISO8601DateFormatter().string(from: s)
            comps.queryItems = [URLQueryItem(name: "since", value: iso)]
        }

        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // 2️⃣ – Request
        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err = err { completion(.failure(err)); return }
            guard let data = data else { completion(.failure(APIError.noData)); return }

            // 3️⃣ – Decode (flexible date strategy)
            do {
                let dec = JSONDecoder()
                dec.dateDecodingStrategy = .custom { d in
                    let c = try d.singleValueContainer()
                    let s = try c.decode(String.self)

                    // try every accepted pattern
                    for fmt in ExerunServerAPIManager.acceptedDateFormats {
                        if let dt = fmt.date(from: s) { return dt }
                    }
                    // fallback to full ISO-8601 (with timezone)
                    if let dt = ISO8601DateFormatter().date(from: s) { return dt }

                    throw DecodingError.dataCorruptedError(
                        in: c,
                        debugDescription: "Unrecognised date format: \(s)"
                    )
                }

                let list = try dec.decode([WorkoutResponse].self, from: data)
                completion(.success(list))

            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }
    
    
    // MARK: – Raw file download (any path that lives under baseURL)
    func download(_ path: String, completion: @escaping(Result<Data,Error>)->Void) {
        let url = baseURL.appendingPathComponent(path)
        URLSession.shared.dataTask(with: url) { data, _, err in
            if let err = err { completion(.failure(err)); return }
            guard let data else { completion(.failure(APIError.noData)); return }
            completion(.success(data))
        }.resume()
    }

    // MARK: – GymPlans › POST /gymplans/generate
    func generateGymPlan(request: GymPlanRequest,
                         completion: @escaping (Result<GymPlanResponse, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(APIError.noToken))
            return
        }

        let url = baseURL.appendingPathComponent("/gymplans/generate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let encoder = JSONEncoder()
            req.httpBody = try encoder.encode(request)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(GymPlanResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: – GymPlans › POST /gymplans/
    func uploadGymPlan(_ plan: GymPlanUploader.UploadableGymPlan,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = authToken else {
            completion(.failure(APIError.noToken)); return
        }

        var req = URLRequest(url: baseURL.appendingPathComponent("/gymplans/"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        req.httpBody = try? JSONEncoder().encode(plan)

        URLSession.shared.dataTask(with: req) { _, resp, err in
            if let err = err { completion(.failure(err)); return }
            guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                completion(.failure(APIError.badStatus)); return
            }
            completion(.success(()))
        }.resume()
    }
    
    // MARK: – GymPlans › Get /gymplans/
    func fetchGymPlans(completion: @escaping (Result<[GymPlanUploader.UploadableGymPlan], Error>) -> Void) {
        print("📡 FETCHING gym plans from server...")
        var req = URLRequest(url: baseURL.appendingPathComponent("/gymplans/me"))
        req.httpMethod = "GET"
        req.setValue("Bearer \(KeychainManager.shared.loadToken() ?? "")", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                completion(.failure(err))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode([GymPlanUploader.UploadableGymPlan].self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

//    // MARK: – (GET /profiles/me/weights)
//    func fetchWeightHistory(since: Date?, completion: @escaping(Result<[WeightEntryDTO],Error>) -> Void) {
//        guard let token = authToken else { completion(.failure(APIError.noToken)); return }
//
//        var comps = URLComponents(url: baseURL.appendingPathComponent("/profiles/me/weights"),
//                                  resolvingAgainstBaseURL: false)!
//        if let since { comps.queryItems = [.init(name: "since", value: ISO8601DateFormatter().string(from: since))] }
//
//        var req = URLRequest(url: comps.url!)
//        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//
//        URLSession.shared.dataTask(with: req) { data,_,err in
//            if let err = err { completion(.failure(err)); return }
//            guard let data = data else { completion(.failure(APIError.noData)); return }
//            do {
//                let list = try JSONDecoder().decode([WeightEntryDTO].self, from: data)
//                completion(.success(list))
//            } catch { completion(.failure(error)) }
//        }.resume()
//    }

    // MARK: – Private helpers
    private func handleTokenResponse(data: Data?,
                                     error: Error?,
                                     completion: @escaping (Result<String,Error>) -> Void) {

        if let error = error { completion(.failure(error)); return }
        guard let data = data else { completion(.failure(APIError.noData)); return }

        do {
            let resp  = try JSONDecoder().decode(TokenResponse.self, from: data)
            let token = resp.access_token
            KeychainManager.shared.saveToken(token)
            completion(.success(token))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Flexible parsers for the three timestamp shapes we’re currently receiving
    private static let acceptedDateFormats: [DateFormatter] = {
        func make(_ pattern: String) -> DateFormatter {
            let df = DateFormatter()
            df.dateFormat = pattern
            df.locale     = .init(identifier: "en_US_POSIX")
            df.timeZone   = .init(secondsFromGMT: 0)
            return df
        }
        return [
            make("yyyy-MM-dd'T'HH:mm:ss.SSSSSS"), // micro-seconds
            make("yyyy-MM-dd'T'HH:mm:ss.SSS"),    // milli-seconds
            make("yyyy-MM-dd'T'HH:mm:ss")         // plain seconds
        ]
    }()

}

// MARK: – Supporting Types
struct TokenResponse: Decodable { let access_token: String }

enum APIError: Error {
    case noData
    case badStatus
    case noToken
}

// MARK: – Small helper -------------------------------------------------------
private extension Data {
    mutating func append(_ string: String) {
        if let d = string.data(using: .utf8) { self.append(d) }
    }
}
