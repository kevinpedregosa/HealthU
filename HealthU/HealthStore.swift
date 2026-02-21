import Foundation
import Combine

@MainActor
final class HealthStore: ObservableObject {
    @Published var universityEmail: String?
    @Published private(set) var personalCheckIns: [CheckIn]
    @Published private(set) var schoolTrend: [SchoolWeeklyAggregate]

    let minimumAnonymousResponses = 10

    init() {
        personalCheckIns = Self.seedPersonalCheckIns()
        schoolTrend = Self.seedSchoolTrend()
    }

    var isLoggedIn: Bool {
        universityEmail != nil
    }

    func login(email: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.contains("@"), normalized.hasSuffix(".edu") else {
            return false
        }

        universityEmail = normalized
        return true
    }

    func logout() {
        universityEmail = nil
    }

    func submitWeeklyCheckIn(stress: Double, sleepQuality: Double, anxiety: Double, academicPressure: Double) {
        let checkIn = CheckIn(
            createdAt: Date(),
            stress: stress,
            sleepQuality: sleepQuality,
            anxiety: anxiety,
            academicPressure: academicPressure
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
            CheckIn(createdAt: start, stress: 3.8, sleepQuality: 2.9, anxiety: 3.4, academicPressure: 4.1),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? Date(), stress: 3.5, sleepQuality: 3.2, anxiety: 3.2, academicPressure: 3.9),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 2, to: start) ?? Date(), stress: 3.9, sleepQuality: 2.8, anxiety: 3.7, academicPressure: 4.3),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 3, to: start) ?? Date(), stress: 3.4, sleepQuality: 3.5, anxiety: 3.0, academicPressure: 3.6),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 4, to: start) ?? Date(), stress: 3.2, sleepQuality: 3.6, anxiety: 2.9, academicPressure: 3.4),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 5, to: start) ?? Date(), stress: 3.6, sleepQuality: 3.3, anxiety: 3.1, academicPressure: 3.8),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 6, to: start) ?? Date(), stress: 3.3, sleepQuality: 3.7, anxiety: 2.8, academicPressure: 3.5),
            CheckIn(createdAt: calendar.date(byAdding: .weekOfYear, value: 7, to: start) ?? Date(), stress: 3.1, sleepQuality: 3.8, anxiety: 2.7, academicPressure: 3.3)
        ]
    }

    private static func seedSchoolTrend() -> [SchoolWeeklyAggregate] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .weekOfYear, value: -7, to: Date()) ?? Date()
        return [
            SchoolWeeklyAggregate(weekStart: start, responseCount: 48, avgStress: 3.7, avgSleepQuality: 3.0, avgAnxiety: 3.3, avgAcademicPressure: 4.0),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? Date(), responseCount: 56, avgStress: 3.6, avgSleepQuality: 3.1, avgAnxiety: 3.2, avgAcademicPressure: 3.9),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 2, to: start) ?? Date(), responseCount: 61, avgStress: 3.8, avgSleepQuality: 2.9, avgAnxiety: 3.4, avgAcademicPressure: 4.2),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 3, to: start) ?? Date(), responseCount: 70, avgStress: 3.5, avgSleepQuality: 3.3, avgAnxiety: 3.1, avgAcademicPressure: 3.8),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 4, to: start) ?? Date(), responseCount: 79, avgStress: 3.4, avgSleepQuality: 3.4, avgAnxiety: 3.0, avgAcademicPressure: 3.7),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 5, to: start) ?? Date(), responseCount: 84, avgStress: 3.5, avgSleepQuality: 3.4, avgAnxiety: 3.0, avgAcademicPressure: 3.8),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 6, to: start) ?? Date(), responseCount: 91, avgStress: 3.3, avgSleepQuality: 3.6, avgAnxiety: 2.9, avgAcademicPressure: 3.6),
            SchoolWeeklyAggregate(weekStart: calendar.date(byAdding: .weekOfYear, value: 7, to: start) ?? Date(), responseCount: 95, avgStress: 3.2, avgSleepQuality: 3.7, avgAnxiety: 2.8, avgAcademicPressure: 3.5)
        ]
    }
}
