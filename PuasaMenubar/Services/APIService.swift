import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://api.aladhan.com/v1"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    func fetchPrayerTimes(
        latitude: Double,
        longitude: Double,
        date: Date = Date()
    ) async throws -> PrayerTimesData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)/timings/\(dateString)"
        guard var urlComponents = URLComponents(string: urlString) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "method", value: "2"),
            URLQueryItem(name: "school", value: "0"),
            URLQueryItem(name: "adjustment", value: "1"),
            URLQueryItem(name: "timezonestring", value: "Asia/Jakarta")
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        print("Fetching from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("Response status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString.prefix(500))...")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let prayerTimesResponse = try decoder.decode(PrayerTimesResponse.self, from: data)
                
                guard prayerTimesResponse.code == 200 else {
                    throw APIError.serverError(prayerTimesResponse.status)
                }
                
                return prayerTimesResponse.data
            } catch {
                print("Decoding error: \(error)")
                throw APIError.decodingError(error)
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
    
    func fetchPrayerTimesByCity(
        city: String,
        country: String,
        date: Date = Date()
    ) async throws -> PrayerTimesData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)/timingsByCity/\(dateString)"
        guard var urlComponents = URLComponents(string: urlString) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "city", value: city),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "method", value: "2"),
            URLQueryItem(name: "timezonestring", value: "Asia/Jakarta")
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        print("Fetching from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("Response status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw response: \(jsonString.prefix(500))...")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let prayerTimesResponse = try decoder.decode(PrayerTimesResponse.self, from: data)
                
                guard prayerTimesResponse.code == 200 else {
                    throw APIError.serverError(prayerTimesResponse.status)
                }
                
                return prayerTimesResponse.data
            } catch {
                print("Decoding error: \(error)")
                throw APIError.decodingError(error)
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
}
