import Foundation
import Combine

enum AuthError: LocalizedError, Equatable {
    case invalidURL
    case networkError(String)
    case decodingError
    case unauthorized
    case serverError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Configuration error. Please contact support."
        case .networkError(let message):
            return "Network issue: \(message). Please check your connection."
        case .decodingError:
            return "We received an unexpected response from the server. Please try again."
        case .unauthorized:
            return "Invalid username or password."
        case .serverError(let message):
            return message // Server usually sends a friendly message now
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let username: String
    let passwordResetRequired: Bool
    let fullName: String?
    let dashboard: AppDashboard?
}

struct RegistrationResponse: Codable {
    let username: String
    let message: String
}

protocol AuthServiceProtocol {
    func signup(firstName: String, lastName: String, email: String) -> AnyPublisher<RegistrationResponse, Error>
    func login(username: String, password: String) -> AnyPublisher<AuthResponse, Error>
}

class AuthService: AuthServiceProtocol {
    private let baseURL = APIConfig.spendVoltBaseURL
    
    private func extractMessage(from data: Data, defaultMessage: String) -> String {
        // 1. Direct JSON extraction - The most common and reliable way
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = json["message"] as? String ?? json["error"] as? String ?? json["errorMessage"] as? String {
            return msg
        }
        
        // 2. String-based fallback for double-encoded or "trapped" JSON
        if let text = String(data: data, encoding: .utf8) {
            // Remove outer quotes if the server sent the JSON inside a string
            let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if let jsonData = trimmed.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let msg = json["message"] as? String ?? json["error"] as? String {
                return msg
            }
            
            // 3. Regex Plucking - Specifically looks for the value of "message"
            let pattern = #""message"\s*:\s*"([^"]+)""#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
            
            // 4. Clean up technical prefixes from plain text (e.g., "400 Bad Request: Message")
            let technicalPattern = #"^(?i)(?:\d{3}\s+)?(?:Bad Request|Unauthorized|Internal Server Error|Forbidden|Error|Failure|Conflict)[:\- ]*"#
            let cleanText = text.replacingOccurrences(of: technicalPattern, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Only return the plain text if it doesn't look like raw JSON
            if !cleanText.isEmpty && !cleanText.hasPrefix("{") {
                return cleanText
            }
        }
        
        return defaultMessage
    }
    
    func signup(firstName: String, lastName: String, email: String) -> AnyPublisher<RegistrationResponse, Error> {
        guard let url = URL(string: "\(baseURL)/public/auth/register") else {
            return Fail(error: AuthError.invalidURL).eraseToAnyPublisher()
        }
        
        let body: [String: String] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AuthError.serverError("Invalid response")
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    return data
                } else {
                    let message = self.extractMessage(from: data, defaultMessage: "Registration failed.")
                    throw AuthError.serverError(message)
                }
            }
            .decode(type: RegistrationResponse.self, decoder: AppCoder.jsonDecoder)
            .mapError { error -> Error in
                if let authError = error as? AuthError { return authError }
                if error is DecodingError { return AuthError.decodingError }
                return AuthError.unknown(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    func login(username: String, password: String) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "\(baseURL)/public/auth/login") else {
            return Fail(error: AuthError.invalidURL).eraseToAnyPublisher()
        }
        
        let body: [String: String] = [
            "username": username,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AuthError.serverError("We're having trouble connecting to our servers.")
                }
                
                if httpResponse.statusCode == 401 {
                    throw AuthError.unauthorized
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let message = self.extractMessage(from: data, defaultMessage: "Login failed. Please try again.")
                    throw AuthError.serverError(message)
                }
                
                return data
            }
            .decode(type: AuthResponse.self, decoder: AppCoder.jsonDecoder)
            .mapError { error -> Error in
                if let authError = error as? AuthError { return authError }
                if let decodingError = error as? DecodingError {
                    print("Critical Decoding Error: \(decodingError)")
                    return AuthError.decodingError
                }
                return AuthError.unknown(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
}

