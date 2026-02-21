import Foundation

struct CheckIn: Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let stress: Double
    let sleepQuality: Double
    let anxiety: Double
    let academicPressure: Double

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        stress: Double,
        sleepQuality: Double,
        anxiety: Double,
        academicPressure: Double
    ) {
        self.id = id
        self.createdAt = createdAt
        self.stress = stress
        self.sleepQuality = sleepQuality
        self.anxiety = anxiety
        self.academicPressure = academicPressure
    }
}

struct SchoolWeeklyAggregate: Identifiable {
    let id: UUID
    let weekStart: Date
    let responseCount: Int
    let avgStress: Double
    let avgSleepQuality: Double
    let avgAnxiety: Double
    let avgAcademicPressure: Double

    init(
        id: UUID = UUID(),
        weekStart: Date,
        responseCount: Int,
        avgStress: Double,
        avgSleepQuality: Double,
        avgAnxiety: Double,
        avgAcademicPressure: Double
    ) {
        self.id = id
        self.weekStart = weekStart
        self.responseCount = responseCount
        self.avgStress = avgStress
        self.avgSleepQuality = avgSleepQuality
        self.avgAnxiety = avgAnxiety
        self.avgAcademicPressure = avgAcademicPressure
    }
}

enum Metric: String, CaseIterable, Identifiable {
    case stress = "Stress"
    case sleepQuality = "Sleep"
    case anxiety = "Anxiety"
    case academicPressure = "Academic Pressure"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .stress:
            return "Stress"
        case .sleepQuality:
            return "Sleep"
        case .anxiety:
            return "Anxiety"
        case .academicPressure:
            return "Pressure"
        }
    }

    func value(from checkIn: CheckIn) -> Double {
        switch self {
        case .stress:
            return checkIn.stress
        case .sleepQuality:
            return checkIn.sleepQuality
        case .anxiety:
            return checkIn.anxiety
        case .academicPressure:
            return checkIn.academicPressure
        }
    }

    func value(from aggregate: SchoolWeeklyAggregate) -> Double {
        switch self {
        case .stress:
            return aggregate.avgStress
        case .sleepQuality:
            return aggregate.avgSleepQuality
        case .anxiety:
            return aggregate.avgAnxiety
        case .academicPressure:
            return aggregate.avgAcademicPressure
        }
    }
}
