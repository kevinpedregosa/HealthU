import Foundation

struct CheckIn: Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let stress: Int
    let anxiety: Int
    let academicPressure: Int
    let sleepQuality: Int
    let sleepQuantity: Double

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        stress: Int,
        anxiety: Int,
        academicPressure: Int,
        sleepQuality: Int,
        sleepQuantity: Double
    ) {
        self.id = id
        self.createdAt = createdAt
        self.stress = stress
        self.anxiety = anxiety
        self.academicPressure = academicPressure
        self.sleepQuality = sleepQuality
        self.sleepQuantity = sleepQuantity
    }
}

struct SchoolWeeklyAggregate: Identifiable {
    let id: UUID
    let weekStart: Date
    let responseCount: Int
    let avgStress: Double
    let avgAnxiety: Double
    let avgAcademicPressure: Double
    let avgSleepQuality: Double
    let avgSleepQuantity: Double

    init(
        id: UUID = UUID(),
        weekStart: Date,
        responseCount: Int,
        avgStress: Double,
        avgAnxiety: Double,
        avgAcademicPressure: Double,
        avgSleepQuality: Double,
        avgSleepQuantity: Double
    ) {
        self.id = id
        self.weekStart = weekStart
        self.responseCount = responseCount
        self.avgStress = avgStress
        self.avgAnxiety = avgAnxiety
        self.avgAcademicPressure = avgAcademicPressure
        self.avgSleepQuality = avgSleepQuality
        self.avgSleepQuantity = avgSleepQuantity
    }
}

enum Metric: String, CaseIterable, Identifiable {
    case stress = "Stress"
    case anxiety = "Anxiety"
    case academicPressure = "Academic Pressure"
    case sleepQuality = "Sleep Quality"
    case sleepQuantity = "Sleep Quantity"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .stress:
            return "Stress"
        case .anxiety:
            return "Anxiety"
        case .academicPressure:
            return "Pressure"
        case .sleepQuality:
            return "Sleep Q"
        case .sleepQuantity:
            return "Sleep Hrs"
        }
    }

    func value(from checkIn: CheckIn) -> Double {
        switch self {
        case .stress:
            return Double(checkIn.stress)
        case .anxiety:
            return Double(checkIn.anxiety)
        case .academicPressure:
            return Double(checkIn.academicPressure)
        case .sleepQuality:
            return Double(checkIn.sleepQuality)
        case .sleepQuantity:
            return checkIn.sleepQuantity
        }
    }

    func value(from aggregate: SchoolWeeklyAggregate) -> Double {
        switch self {
        case .stress:
            return aggregate.avgStress
        case .anxiety:
            return aggregate.avgAnxiety
        case .academicPressure:
            return aggregate.avgAcademicPressure
        case .sleepQuality:
            return aggregate.avgSleepQuality
        case .sleepQuantity:
            return aggregate.avgSleepQuantity
        }
    }

    func formatted(_ value: Double) -> String {
        if self == .sleepQuantity {
            return "\(value.formatted(.number.precision(.fractionLength(1)))) h"
        }

        if value.rounded() == value {
            return "\(Int(value))"
        }

        return value.formatted(.number.precision(.fractionLength(1)))
    }
}
