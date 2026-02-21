import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var store = HealthStore()

    var body: some View {
        Group {
            if store.isLoggedIn {
                MainDashboardView()
                    .environmentObject(store)
            } else {
                LoginView()
                    .environmentObject(store)
            }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var store: HealthStore
    @State private var email = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("HealthU")
                    .font(.system(size: 38, weight: .bold, design: .rounded))

                Text("Anonymous weekly well-being check-ins for students, with trend insights for you and your campus.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("University Email")
                        .font(.headline)

                    TextField("you@university.edu", text: $email)
                        .autocorrectionDisabled()
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Button("Continue") {
                    let success = store.login(email: email)
                    errorMessage = success ? nil : "Use a valid university email address ending in .edu."
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Text("Privacy note: school analytics are displayed only after enough responses are collected to preserve anonymity.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }
}

struct MainDashboardView: View {
    @EnvironmentObject private var store: HealthStore

    var body: some View {
        TabView {
            WeeklyCheckInView()
                .tabItem {
                    Label("Check-In", systemImage: "checklist")
                }

            PersonalTrendsView()
                .tabItem {
                    Label("My Trends", systemImage: "waveform.path.ecg")
                }

            SchoolTrendsView()
                .tabItem {
                    Label("School Trends", systemImage: "building.2")
                }
        }
        .toolbar {
            ToolbarItem {
                Button("Log Out") {
                    store.logout()
                }
            }
        }
    }
}

struct WeeklyCheckInView: View {
    @EnvironmentObject private var store: HealthStore

    @State private var stress: Double = 3
    @State private var sleepQuality: Double = 3
    @State private var anxiety: Double = 3
    @State private var academicPressure: Double = 3
    @State private var submitted = false

    var body: some View {
        NavigationStack {
            Form {
                Section("How are you this week?") {
                    MetricSlider(label: "Stress", value: $stress)
                    MetricSlider(label: "Sleep Quality", value: $sleepQuality)
                    MetricSlider(label: "Anxiety", value: $anxiety)
                    MetricSlider(label: "Academic Pressure", value: $academicPressure)
                }

                Section {
                    Button("Submit Weekly Check-In") {
                        store.submitWeeklyCheckIn(
                            stress: stress,
                            sleepQuality: sleepQuality,
                            anxiety: anxiety,
                            academicPressure: academicPressure
                        )
                        submitted = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                if submitted {
                    Section {
                        Text("Thanks. Your check-in was saved and included in your personal trends.")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Weekly Check-In")
        }
    }
}

struct PersonalTrendsView: View {
    @EnvironmentObject private var store: HealthStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your last \(store.personalCheckIns.count) weekly check-ins")
                        .font(.headline)

                    personalTrendChart
                        .frame(height: 280)

                    HStack(spacing: 12) {
                        ForEach(Metric.allCases) { metric in
                            if let value = store.latestValue(for: metric) {
                                InsightCard(title: metric.shortLabel, value: value)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Trends")
        }
    }

    private var personalTrendChart: some View {
        Chart {
            ForEach(Metric.allCases) { metric in
                ForEach(store.personalCheckIns) { checkIn in
                    LineMark(
                        x: .value("Week", checkIn.createdAt),
                        y: .value(metric.rawValue, metric.value(from: checkIn))
                    )
                    .foregroundStyle(by: .value("Metric", metric.rawValue))
                    .symbol(by: .value("Metric", metric.rawValue))
                }
            }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct SchoolTrendsView: View {
    @EnvironmentObject private var store: HealthStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Anonymous campus-level insights")
                        .font(.headline)

                    if store.canShowSchoolAverages {
                        schoolTrendChart
                            .frame(height: 280)

                        if let latest = store.schoolTrend.last {
                            Text("Latest participation: \(latest.responseCount) responses")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not enough responses yet to safely display school averages.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("School Trends")
        }
    }

    private var schoolTrendChart: some View {
        Chart {
            ForEach(Metric.allCases) { metric in
                ForEach(store.schoolTrend) { aggregate in
                    LineMark(
                        x: .value("Week", aggregate.weekStart),
                        y: .value(metric.rawValue, metric.value(from: aggregate))
                    )
                    .foregroundStyle(by: .value("Metric", metric.rawValue))
                }
            }
        }
        .chartYScale(domain: 1...5)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct MetricSlider: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                Spacer()
                Text(value.formatted(.number.precision(.fractionLength(1))))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: 1...5, step: 0.1)
                .tint(.indigo)
        }
        .padding(.vertical, 4)
    }
}

struct InsightCard: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.formatted(.number.precision(.fractionLength(1))))
                .font(.title3.bold())
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
