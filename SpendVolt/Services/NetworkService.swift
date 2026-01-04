import Foundation
import Combine

enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Configuration error. Please contact support."
        case .noData:
            return "No data received from the server. Please try again."
        case .decodingError:
            return "We couldn't read the server's response. Please check for app updates."
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .unknown(let message):
            return "A network error occurred: \(message)"
        }
    }
}

protocol NetworkServiceProtocol {
    func fetchTransactions(from: Date?, to: Date?) -> AnyPublisher<[Transaction], Error>
    func createTransaction(_ transaction: Transaction) -> AnyPublisher<AppDashboard, Error>
    func deleteTransaction(id: Int) -> AnyPublisher<AppDashboard, Error>
    func updateTransactionCategory(id: Int, categoryName: String) -> AnyPublisher<AppDashboard, Error>
    func updateTransactionStatus(id: Int, status: String) -> AnyPublisher<AppDashboard, Error>
    func fetchProfile() -> AnyPublisher<UserProfile, Error>
    func updateProfile(_ profile: UserProfile) -> AnyPublisher<AppDashboard, Error>
    func fetchCategories() -> AnyPublisher<[UserCategory], Error>
    func createCategory(_ category: UserCategory) -> AnyPublisher<AppDashboard, Error>
    func deleteCategory(id: Int) -> AnyPublisher<AppDashboard, Error>
    func fetchStats() -> AnyPublisher<BackendStats, Error>
    func fetchDashboard(from: Date?, to: Date?) -> AnyPublisher<AppDashboard, Error>
    
    // Recurring Transactions
    func fetchRecurringTransactions() -> AnyPublisher<[RecurringTransaction], Error>
    func createRecurringTransaction(_ transaction: RecurringTransaction) -> AnyPublisher<AppDashboard, Error>
    func deleteRecurringTransaction(id: String) -> AnyPublisher<AppDashboard, Error>
}

class NetworkService: NetworkServiceProtocol {
    private let baseURL = APIConfig.spendVoltBaseURL
    private let sessionManager: SessionManagerProtocol
    
    init(sessionManager: SessionManagerProtocol = SessionManager.shared) {
        self.sessionManager = sessionManager
    }

    private var authToken: String? {
        return sessionManager.authToken
    }

    private func extractMessage(from data: Data, defaultMessage: String) -> String {
        // 1. Direct JSON extraction
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let msg = json["message"] as? String ?? json["error"] as? String ?? json["errorMessage"] as? String {
            return msg
        }
        
        // 2. String-based fallback
        if let text = String(data: data, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if let jsonData = trimmed.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let msg = json["message"] as? String ?? json["error"] as? String {
                return msg
            }
            
            // 3. Regex Plucking
            let pattern = #""message"\s*:\s*"([^"]+)""#
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
            
            // 4. Cleanup technical prefixes
            let technicalPattern = #"^(?i)(?:\d{3}\s+)?(?:Bad Request|Unauthorized|Internal Server Error|Forbidden|Error|Failure|Conflict)[:\- ]*"#
            let cleanText = text.replacingOccurrences(of: technicalPattern, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !cleanText.isEmpty && !cleanText.hasPrefix("{") {
                return cleanText
            }
        }
        
        return defaultMessage
    }

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.serverError("We're having trouble connecting to our servers.")
                }
                
                if httpResponse.statusCode == 401 {
                    throw NetworkError.unauthorized
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let message = self.extractMessage(from: data, defaultMessage: "The server encountered an issue.")
                    throw NetworkError.serverError(message)
                }
                
                return data
            }
            .decode(type: T.self, decoder: AppCoder.jsonDecoder)
            .mapError { error -> Error in
                if let networkError = error as? NetworkError { return networkError }
                if let decodingError = error as? DecodingError {
                    print("Critical Network Decoding Error: \(decodingError)")
                    return NetworkError.decodingError
                }
                return NetworkError.unknown(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }

    func fetchTransactions(from: Date?, to: Date?) -> AnyPublisher<[Transaction], Error> {
        var path = "/transactions"
        var queryItems: [URLQueryItem] = []
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let from = from {
            queryItems.append(URLQueryItem(name: "from", value: formatter.string(from: from)))
        }
        if let to = to {
            queryItems.append(URLQueryItem(name: "to", value: formatter.string(from: to)))
        }
        
        if !queryItems.isEmpty {
            var components = URLComponents()
            components.queryItems = queryItems
            if let query = components.query {
                path += "?\(query)"
            }
        }
        
        return request(path)
    }

    func createTransaction(_ transaction: Transaction) -> AnyPublisher<AppDashboard, Error> {
        guard let data = try? AppCoder.jsonEncoder.encode(transaction) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        
        print("Creating transaction: \(String(data: data, encoding: .utf8) ?? "")")
        return request("/transactions", method: "POST", body: data)
    }

    func deleteTransaction(id: Int) -> AnyPublisher<AppDashboard, Error> {
        return request("/transactions/\(id)", method: "DELETE")
    }

    func updateTransactionCategory(id: Int, categoryName: String) -> AnyPublisher<AppDashboard, Error> {
        return request("/transactions/\(id)/category?categoryName=\(categoryName)", method: "PATCH")
    }

    func updateTransactionStatus(id: Int, status: String) -> AnyPublisher<AppDashboard, Error> {
        return request("/transactions/\(id)/status?status=\(status)", method: "PATCH")
    }

    func fetchProfile() -> AnyPublisher<UserProfile, Error> {
        return request("/user/profile")
    }

    func updateProfile(_ profile: UserProfile) -> AnyPublisher<AppDashboard, Error> {
        guard let data = try? AppCoder.jsonEncoder.encode(profile) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        return request("/user/profile", method: "PUT", body: data)
    }

    func fetchCategories() -> AnyPublisher<[UserCategory], Error> {
        return request("/categories")
    }

    func createCategory(_ category: UserCategory) -> AnyPublisher<AppDashboard, Error> {
        guard let data = try? AppCoder.jsonEncoder.encode(category) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        return request("/categories", method: "POST", body: data)
    }

    func deleteCategory(id: Int) -> AnyPublisher<AppDashboard, Error> {
        return request("/categories/\(id)", method: "DELETE")
    }

    func fetchStats() -> AnyPublisher<BackendStats, Error> {
        return request("/stats")
    }

    func fetchDashboard(from: Date?, to: Date?) -> AnyPublisher<AppDashboard, Error> {
        var path = "/dashboard"
        var queryItems: [URLQueryItem] = []
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let from = from {
            queryItems.append(URLQueryItem(name: "from", value: formatter.string(from: from)))
        }
        if let to = to {
            queryItems.append(URLQueryItem(name: "to", value: formatter.string(from: to)))
        }
        
        if !queryItems.isEmpty {
            var components = URLComponents()
            components.queryItems = queryItems
            if let query = components.query {
                path += "?\(query)"
            }
        }
        
        return request(path)
    }

    // MARK: - Recurring Transactions
    func fetchRecurringTransactions() -> AnyPublisher<[RecurringTransaction], Error> {
        return request("/recurring")
    }

    func createRecurringTransaction(_ transaction: RecurringTransaction) -> AnyPublisher<AppDashboard, Error> {
        guard let data = try? AppCoder.jsonEncoder.encode(transaction) else {
            return Fail(error: NetworkError.decodingError).eraseToAnyPublisher()
        }
        return request("/recurring", method: "POST", body: data)
    }

    func deleteRecurringTransaction(id: String) -> AnyPublisher<AppDashboard, Error> {
        return request("/recurring/\(id)", method: "DELETE")
    }
}

