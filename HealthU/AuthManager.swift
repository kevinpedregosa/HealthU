import Foundation
import AuthenticationServices

struct AuthSession: Decodable {
    let sessionToken: String
    let expiresIn: Int
    let email: String
    let isStudent: Bool
}

struct AuthStartResponse: Decodable {
    let authorizationURL: URL
    let state: String
    let callbackScheme: String

    enum CodingKeys: String, CodingKey {
        case authorizationURL = "authorizationUrl"
        case state
        case callbackScheme
    }
}

struct AuthCallbackRequest: Encodable {
    let code: String
    let state: String
}

enum AuthError: LocalizedError {
    case missingBackendURL
    case malformedCallback
    case userCancelled
    case invalidServerResponse
    case backendError(String)

    var errorDescription: String? {
        switch self {
        case .missingBackendURL:
            return "Missing API base URL. Add AUTH_API_BASE_URL to Info.plist."
        case .malformedCallback:
            return "Login callback was malformed."
        case .userCancelled:
            return "Sign in was canceled."
        case .invalidServerResponse:
            return "Unexpected server response during sign in."
        case .backendError(let message):
            return message
        }
    }
}

@MainActor
final class AuthManager: NSObject {
    private var webSession: ASWebAuthenticationSession?

    private var apiBaseURL: URL? {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "AUTH_API_BASE_URL") as? String {
            let normalized = configured.trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: normalized), !normalized.isEmpty {
                return url
            }
        }

        if let url = URL(string: "http://127.0.0.1:4000") {
            return url
        }
        return nil
    }

    func signInWithUCI(emailHint: String?) async throws -> AuthSession {
        guard let apiBaseURL else {
            throw AuthError.missingBackendURL
        }

        var startComponents = URLComponents(url: apiBaseURL.appendingPathComponent("auth/uci/start"), resolvingAgainstBaseURL: false)
        if let hint = emailHint?.trimmingCharacters(in: .whitespacesAndNewlines), !hint.isEmpty {
            startComponents?.queryItems = [URLQueryItem(name: "email_hint", value: hint)]
        }

        guard let startURL = startComponents?.url else {
            throw AuthError.missingBackendURL
        }

        var startRequest = URLRequest(url: startURL)
        startRequest.httpMethod = "GET"

        let (startData, startResponse) = try await URLSession.shared.data(for: startRequest)
        guard let http = startResponse as? HTTPURLResponse else {
            throw AuthError.invalidServerResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: startData, encoding: .utf8) ?? "Unable to start sign in."
            throw AuthError.backendError(message)
        }

        let startPayload = try JSONDecoder().decode(AuthStartResponse.self, from: startData)
        let callbackURL = try await authorizeInBrowser(
            url: startPayload.authorizationURL,
            callbackScheme: startPayload.callbackScheme
        )

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let code = queryItems.first(where: { $0.name == "code" })?.value,
              let state = queryItems.first(where: { $0.name == "state" })?.value else {
            throw AuthError.malformedCallback
        }

        let callbackRequest = AuthCallbackRequest(
            code: code,
            state: state
        )

        var exchange = URLRequest(url: apiBaseURL.appendingPathComponent("auth/uci/callback"))
        exchange.httpMethod = "POST"
        exchange.setValue("application/json", forHTTPHeaderField: "Content-Type")
        exchange.httpBody = try JSONEncoder().encode(callbackRequest)

        let (exchangeData, exchangeResponse) = try await URLSession.shared.data(for: exchange)
        guard let exchangeHTTP = exchangeResponse as? HTTPURLResponse else {
            throw AuthError.invalidServerResponse
        }

        guard (200..<300).contains(exchangeHTTP.statusCode) else {
            let message = String(data: exchangeData, encoding: .utf8) ?? "Unable to complete sign in."
            throw AuthError.backendError(message)
        }

        return try JSONDecoder().decode(AuthSession.self, from: exchangeData)
    }

    private func authorizeInBrowser(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: AuthError.userCancelled)
                    return
                }

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: AuthError.malformedCallback)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            #if os(iOS)
            session.prefersEphemeralWebBrowserSession = true
            #endif

            self.webSession = session
            session.start()
        }
    }
}
