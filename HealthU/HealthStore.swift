import Foundation
import Combine

@MainActor
final class HealthStore: ObservableObject {
    @Published var universityEmail: String?
    @Published var sessionToken: String?
    @Published var authError: String?
    @Published private(set) var personalCheckIns: [CheckIn]
    @Published private(set) var schoolTrend: [SchoolWeeklyAggregate]

    let minimumAnonymousResponses = 10
    private let authManager = AuthManager()

    init() {
        personalCheckIns = Self.seedPersonalCheckIns()
        schoolTrend = Self.seedSchoolTrend()
    }

    var isLoggedIn: Bool {
        universityEmail != nil && sessionToken != nil
    }

    func login(email: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.hasSuffix("@uci.edu") else {
            return false
        }

        universityEmail = normalized
        sessionToken = "local-dev-session"
        return true
    }

    func loginWithUCI(emailHint: String?) async -> Bool {
        do {
            let session = try await authManager.signInWithUCI(emailHint: emailHint)
            guard session.email.hasSuffix("@uci.edu"), session.isStudent else {
                authError = "Only verified UCI student accounts can use HealthU."
                return false
            }

            universityEmail = session.email
            sessionToken = session.sessionToken
            authError = nil
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func logout() {
        universityEmail = nil
        sessionToken = nil
        authError = nil
    }

    func submitWeeklyCheckIn(
        stress: Int,
        anxiety: Int,
        academicPressure: Int,
        sleepQuality: Int,
        sleepQuantity: Double
    ) {
        let checkIn = CheckIn(
            createdAt: Date(),
            stress: stress,
            anxiety: anxiety,
            academicPressure: academicPressure,
            sleepQuality: sleepQuality,
            sleepQuantity: sleepQuantity
        )
        personalCheckIns.append(checkIn)
        personalCheckIns.sort { $0.createdAt < $1.createdAt }
    }

    func latestValue(for metric: Metric) -> Double? {
        guard let latest = personalCheckIns.last else { return nil }
        return metric.value(from: latest)
    }

    var canShowSchoolAverages: Bool {
        schoolTrend.last?.responseCount ?? 0 >= minimumAnonymousResponses
    }

    private static func seedPersonalCheckIns() -> [CheckIn] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .weekOfYear, value: -7, to: Date()) ?? Date()
        return [
            CheckIn(createdAt: start, stress: 8, anxiety: 7, academicPressure: 9, sleepQuality: 4, sleepQuantity: 5.6),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? Date(), stress: 7, anxiety: 6, academicPressure: 8, sleepQuality: 5, sleepQuantity: 6.2),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 2, to: start) ?? Date(), stress: 8, anxiety: 8, academicPressure: 9, sleepQuality: 4, sleepQuantity: 5.4),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 3, to: start) ?? Date(), stress: 7, anxiety: 6, academicPressure: 7, sleepQuality: 6, sleepQuantity: 6.8),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 4, to: start) ?? Date(), stress: 6, anxiety: 5, academicPressure: 7, sleepQuality: 7, sleepQuantity: 7.0),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 5, to: start) ?? Date(), stress: 7, anxiety: 6, academicPressure: 8, sleepQuality: 6, sleepQuantity: 6.7),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 6, to: start) ?? Date(), stress: 6, anxiety: 5, academicPressure: 7, sleepQuality: 7, sleepQuantity: 7.1),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 7, to: start) ?? Date(), stress: 5, anxiety: 4, academicPressure: 6, sleepQuality: 8, sleepQuantity: 7.4)
        ]
    }

    private static func seedSchoolTrend() -> [SchoolWeeklyAggregate] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .weekOfYear, value: -7, to: Date()) ?? Date()
        return [
            SchoolWeeklyAggregate(weekStart: start, responseCount: 48, avgStress: 7.6, avgAnxiety: 7.1, avgAcademicPressure: 8.4, avgSleepQuality: 4.8, avgSleepQuantity: 5.9),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? Date(), responseCount: 56, avgStress: 7.4, avgAnxiety: 6.8, avgAcademicPressure: 8.1, avgSleepQuality: 5.1, avgSleepQuantity: 6.1),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 2, to: start) ?? Date(), responseCount: 61, avgStress: 7.8, avgAnxiety: 7.3, avgAcademicPressure: 8.7, avgSleepQuality: 4.6, avgSleepQuantity: 5.7),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 3, to: start) ?? Date(), responseCount: 70, avgStress: 7.1, avgAnxiety: 6.5, avgAcademicPressure: 7.9, avgSleepQuality: 5.5, avgSleepQuantity: 6.4),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 4, to: start) ?? Date(), responseCount: 79, avgStress: 6.9, avgAnxiety: 6.2, avgAcademicPressure: 7.6, avgSleepQuality: 5.9, avgSleepQuantity: 6.7),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 5, to: start) ?? Date(), responseCount: 84, avgStress: 7.0, avgAnxiety: 6.3, avgAcademicPressure: 7.8, avgSleepQuality: 5.8, avgSleepQuantity: 6.6),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 6, to: start) ?? Date(), responseCount: 91, avgStress: 6.6, avgAnxiety: 5.9, avgAcademicPressure: 7.2, avgSleepQuality: 6.2, avgSleepQuantity: 7.0),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 7, to: start) ?? Date(), responseCount: 95, avgStress: 6.3, avgAnxiety: 5.6, avgAcademicPressure: 6.9, avgSleepQuality: 6.5, avgSleepQuantity: 7.2)
        ]
    }
}
