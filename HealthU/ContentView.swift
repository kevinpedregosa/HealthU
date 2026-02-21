import SwiftUI
import Charts

private enum AppTheme {
    static let blush = Color(red: 0.62, green: 0.49, blue: 0.36)
    static let mist = Color(red: 0.53, green: 0.40, blue: 0.28)
    static let stone = Color(red: 0.68, green: 0.70, blue: 0.72)
    static let graphite = Color(red: 0.90, green: 0.90, blue: 0.90)
    static let hotPink = Color(red: 0.88, green: 0.47, blue: 0.60)
    static let hotPinkDark = Color(red: 0.85, green: 0.34, blue: 0.53)
    static let leafGreen = Color(red: 0.45, green: 0.71, blue: 0.18)

    static func regular(_ size: CGFloat) -> Font { .custom("Roboto-Regular", size: size) }
    static func bold(_ size: CGFloat) -> Font { .custom("Roboto-Bold", size: size) }
}

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
        .font(AppTheme.regular(16))
        .background(AppTheme.mist)
        .tint(AppTheme.leafGreen)
    }
}

struct LoginView: View {
    @EnvironmentObject private var store: HealthStore
    @State private var email = ""
    @State private var errorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                GeometricBackground()

                VStack(spacing: 24) {
                    AppLogo()

                    Text("Anonymous weekly well-being check-ins with trend insights for the UC Irvine student community.")
                        .font(AppTheme.regular(16))
                        .foregroundStyle(AppTheme.graphite)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)

                    VStack(spacing: 12) {
                        Text("Enter your UCI email")
                            .font(AppTheme.bold(18))
                            .foregroundStyle(AppTheme.graphite)

                        TextField("you@uci.edu", text: $email)
                            .autocorrectionDisabled()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 360)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppTheme.regular(13))
                                .foregroundStyle(.red)
                        }
                    }

                    Button {
                        errorMessage = nil
                        isSigningIn = true
                        Task {
                            let success = await store.loginWithUCI(emailHint: email)
                            if !success {
                                errorMessage = store.authError ?? "Sign in failed. Please try again."
                            }
                            isSigningIn = false
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isSigningIn {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            }
                            Text(isSigningIn ? "Connecting to UCI SSO..." : "Continue with UCI SSO")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .font(AppTheme.bold(24))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                    .disabled(isSigningIn)
                }
                .padding(28)
            }
            .navigationTitle("Welcome")
        }
    }
}

struct MainDashboardView: View {
    @EnvironmentObject private var store: HealthStore

    var body: some View {
        TabView {
            WeeklyCheckInView()
                .tabItem { Label("Check-in", systemImage: "checklist") }

            PersonalTrendsView()
                .tabItem { Label("Personal", systemImage: "waveform.path.ecg") }

            SchoolTrendsView()
                .tabItem { Label("UCI", systemImage: "building.2") }
        }
        .toolbar {
            ToolbarItem {
                Button("Log Out") { store.logout() }
            }
        }
    }
}

struct WeeklyCheckInView: View {
    @EnvironmentObject private var store: HealthStore

    @State private var stress: Int = 5
    @State private var anxiety: Int = 5
    @State private var academicPressure: Int = 5
    @State private var sleepQuality: Int = 5
    @State private var sleepQuantityInput = "7.0"
    @State private var submitted = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                GeometricBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        Text("Weekly Check-In")
                            .font(AppTheme.bold(28))
                            .foregroundStyle(AppTheme.leafGreen)
                            .frame(maxWidth: .infinity)

                        Text("How are you this week?")
                            .font(AppTheme.bold(20))
                            .foregroundStyle(AppTheme.graphite)
                            .frame(maxWidth: .infinity)

                        IntegerMetricSlider(label: "Stress Level", value: $stress)
                        IntegerMetricSlider(label: "Anxiety Level", value: $anxiety)
                        IntegerMetricSlider(label: "Academic Pressure", value: $academicPressure)
                        IntegerMetricSlider(label: "Sleep Quality", value: $sleepQuality)

                        VStack(spacing: 8) {
                            Text("Sleep Quantity (hours/night)")
                                .font(AppTheme.regular(16))
                                .foregroundStyle(AppTheme.graphite)
                            TextField("e.g. 7.5", text: $sleepQuantityInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 240)
                        }
                        .frame(maxWidth: .infinity)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppTheme.regular(14))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                        }

                        Button("Submit Weekly Check-In") {
                            guard let sleepQuantity = Double(sleepQuantityInput), sleepQuantity > 0, sleepQuantity <= 24 else {
                                submitted = false
                                errorMessage = "Enter a valid sleep quantity between 0 and 24 hours."
                                return
                            }

                            store.submitWeeklyCheckIn(
                                stress: stress,
                                anxiety: anxiety,
                                academicPressure: academicPressure,
                                sleepQuality: sleepQuality,
                                sleepQuantity: sleepQuantity
                            )

                            errorMessage = nil
                            submitted = true
                        }
                        .buttonStyle(.borderedProminent)

                        if submitted {
                            Text("Thanks. Your check-in was saved and added to your trends.")
                                .font(AppTheme.regular(14))
                                .foregroundStyle(.green)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .navigationTitle("Check-in")
        }
    }
}

struct PersonalTrendsView: View {
    @EnvironmentObject private var store: HealthStore

    private var personalOneToTenBoxStats: [BoxMetricSummary] {
        oneToTenMetrics.compactMap { metric in
            BoxMetricSummary(metric: metric, values: store.personalCheckIns.map { metric.value(from: $0) })
        }
    }

    private var personalSleepHistogram: [HistogramBin] {
        HistogramBin.build(values: store.personalCheckIns.map { $0.sleepQuantity }, in: 0...12, binSize: 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GeometricBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Your last \(store.personalCheckIns.count) weekly check-ins")
                            .font(AppTheme.bold(20))
                            .foregroundStyle(AppTheme.graphite)

                        themedPanel { personalTrendChart.frame(height: 280) }

                        Text("Boxplots (1-10 scales)")
                            .font(AppTheme.bold(18))
                            .foregroundStyle(AppTheme.graphite)
                        themedPanel { boxplotChart(stats: personalOneToTenBoxStats).frame(height: 260) }

                        Text("Histogram (sleep hours)")
                            .font(AppTheme.bold(18))
                            .foregroundStyle(AppTheme.graphite)
                        themedPanel { sleepHistogramChart(bins: personalSleepHistogram).frame(height: 240) }

                        HStack(spacing: 12) {
                            ForEach(Metric.allCases) { metric in
                                if let value = store.latestValue(for: metric) {
                                    InsightCard(metric: metric, value: value)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Personal")
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
        .chartYScale(domain: 0...max(10, maxPersonalValue + 0.5))
        .chartYAxis { AxisMarks(position: .leading) }
    }

    private var maxPersonalValue: Double {
        store.personalCheckIns
            .flatMap { checkIn in Metric.allCases.map { $0.value(from: checkIn) } }
            .max() ?? 10
    }
}

struct SchoolTrendsView: View {
    @EnvironmentObject private var store: HealthStore

    private var schoolOneToTenBoxStats: [BoxMetricSummary] {
        oneToTenMetrics.compactMap { metric in
            BoxMetricSummary(metric: metric, values: store.schoolTrend.map { metric.value(from: $0) })
        }
    }

    private var schoolSleepHistogram: [HistogramBin] {
        HistogramBin.build(values: store.schoolTrend.map { $0.avgSleepQuantity }, in: 0...12, binSize: 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GeometricBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let latest = store.schoolTrend.last {
                            Text("\(latest.responseCount) students participated in the most recent check-in")
                                .font(AppTheme.regular(13))
                                .foregroundStyle(AppTheme.graphite)
                        }

                        Text("School averages from last \(store.schoolTrend.count) weekly check-ins")
                            .font(AppTheme.bold(20))
                            .foregroundStyle(AppTheme.graphite)

                        if store.canShowSchoolAverages {
                            themedPanel { schoolTrendChart.frame(height: 280) }

                            Text("Boxplots (1-10 scales)")
                                .font(AppTheme.bold(18))
                                .foregroundStyle(AppTheme.graphite)
                            themedPanel { boxplotChart(stats: schoolOneToTenBoxStats).frame(height: 260) }

                            Text("Histogram (sleep hours)")
                                .font(AppTheme.bold(18))
                                .foregroundStyle(AppTheme.graphite)
                            themedPanel { sleepHistogramChart(bins: schoolSleepHistogram).frame(height: 240) }

                        } else {
                            Text("Not enough responses yet to safely display UC Irvine averages.")
                                .font(AppTheme.regular(16))
                                .foregroundStyle(AppTheme.graphite)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("UCI")
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
        .chartYScale(domain: 0...max(10, maxSchoolValue + 0.5))
        .chartYAxis { AxisMarks(position: .leading) }
    }

    private var maxSchoolValue: Double {
        store.schoolTrend
            .flatMap { aggregate in Metric.allCases.map { $0.value(from: aggregate) } }
            .max() ?? 10
    }
}

struct IntegerMetricSlider: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(AppTheme.bold(16))
                .foregroundStyle(AppTheme.graphite)
                .frame(maxWidth: .infinity)

            Text("\(value)")
                .font(AppTheme.regular(16))
                .foregroundStyle(AppTheme.leafGreen)
                .frame(maxWidth: .infinity)

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        let rounded = Int(newValue.rounded())
                        value = min(max(rounded, 1), 10)
                    }
                ),
                in: 0...10,
                step: 1
            )
            .tint(AppTheme.leafGreen)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(AppTheme.blush.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.leafGreen.opacity(0.35), lineWidth: 1)
        )
    }
}

struct InsightCard: View {
    let metric: Metric
    let value: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text(metric.shortLabel)
                .font(AppTheme.regular(12))
                .foregroundStyle(AppTheme.graphite)
            Text(metric.formatted(value))
                .font(AppTheme.bold(20))
                .foregroundStyle(AppTheme.leafGreen)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.blush)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.leafGreen.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct GeometricBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.mist, AppTheme.blush],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height

                Diamond()
                    .fill(AppTheme.stone.opacity(0.15))
                    .frame(width: w * 0.24, height: w * 0.24)
                    .position(x: w * 0.12, y: h * 0.14)

                Diamond()
                    .fill(AppTheme.hotPink.opacity(0.16))
                    .frame(width: w * 0.18, height: w * 0.18)
                    .position(x: w * 0.88, y: h * 0.84)

                Diamond()
                    .fill(AppTheme.graphite.opacity(0.10))
                    .frame(width: w * 0.15, height: w * 0.15)
                    .position(x: w * 0.84, y: h * 0.20)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

private struct BrandMark: View {
    var body: some View {
        HStack(spacing: 10) {
            Diamond().fill(AppTheme.stone).frame(width: 36, height: 36)
            Diamond().fill(AppTheme.graphite).frame(width: 46, height: 46)
            Diamond().fill(AppTheme.hotPink).frame(width: 32, height: 32)
            Diamond().fill(AppTheme.graphite).frame(width: 46, height: 46)
            Diamond().fill(AppTheme.stone).frame(width: 36, height: 36)
        }
    }
}

private struct AppLogo: View {
    var body: some View {
        Image("colored-logo")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: 300)
            .shadow(color: AppTheme.graphite.opacity(0.15), radius: 8, y: 4)
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private let oneToTenMetrics: [Metric] = [.stress, .anxiety, .academicPressure, .sleepQuality]

private struct BoxMetricSummary: Identifiable {
    let metric: Metric
    let q1: Double
    let median: Double
    let q3: Double
    let whiskerLow: Double
    let whiskerHigh: Double
    let outliers: [Double]

    var id: String { metric.id }

    init?(metric: Metric, values: [Double]) {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return nil }

        self.metric = metric
        q1 = Self.quantile(sorted, 0.25)
        median = Self.quantile(sorted, 0.5)
        q3 = Self.quantile(sorted, 0.75)

        let iqr = q3 - q1
        let lowerFence = q1 - (1.5 * iqr)
        let upperFence = q3 + (1.5 * iqr)

        let inRangeValues = sorted.filter { $0 >= lowerFence && $0 <= upperFence }
        whiskerLow = inRangeValues.first ?? (sorted.first ?? 0)
        whiskerHigh = inRangeValues.last ?? (sorted.last ?? 0)
        outliers = sorted.filter { $0 < lowerFence || $0 > upperFence }
    }

    private static func quantile(_ sorted: [Double], _ q: Double) -> Double {
        guard sorted.count > 1 else { return sorted.first ?? 0 }
        let position = q * Double(sorted.count - 1)
        let lower = Int(position.rounded(.down))
        let upper = Int(position.rounded(.up))
        let weight = position - Double(lower)
        return sorted[lower] * (1 - weight) + sorted[upper] * weight
    }
}

private struct HistogramBin: Identifiable {
    let start: Double
    let end: Double
    let count: Int

    var id: String { "\(start)-\(end)" }

    var label: String {
        "\(Int(start))-\(Int(end))"
    }

    static func build(values: [Double], in range: ClosedRange<Double>, binSize: Double) -> [HistogramBin] {
        guard binSize > 0 else { return [] }

        var bins: [HistogramBin] = []
        var currentStart = range.lowerBound

        while currentStart < range.upperBound {
            let currentEnd = min(currentStart + binSize, range.upperBound)
            let count = values.filter { value in
                if currentEnd == range.upperBound {
                    return value >= currentStart && value <= currentEnd
                }
                return value >= currentStart && value < currentEnd
            }.count

            bins.append(HistogramBin(start: currentStart, end: currentEnd, count: count))
            currentStart = currentEnd
        }

        return bins
    }
}

@ViewBuilder
private func boxplotChart(stats: [BoxMetricSummary]) -> some View {
    Chart(stats) { stat in
        RuleMark(
            x: .value("Metric", stat.metric.rawValue),
            yStart: .value("Whisker Low", stat.whiskerLow),
            yEnd: .value("Whisker High", stat.whiskerHigh)
        )
        .foregroundStyle(AppTheme.graphite.opacity(0.9))
        .lineStyle(StrokeStyle(lineWidth: 2))

        BarMark(
            x: .value("Metric", stat.metric.rawValue),
            yStart: .value("Q1", stat.q1),
            yEnd: .value("Q3", stat.q3)
        )
        .foregroundStyle(AppTheme.hotPink.opacity(0.4))
        .cornerRadius(4)

        PointMark(
            x: .value("Metric", stat.metric.rawValue),
            y: .value("Whisker Low", stat.whiskerLow)
        )
        .foregroundStyle(AppTheme.graphite)
        .symbolSize(55)

        PointMark(
            x: .value("Metric", stat.metric.rawValue),
            y: .value("Whisker High", stat.whiskerHigh)
        )
        .foregroundStyle(AppTheme.graphite)
        .symbolSize(55)

        PointMark(
            x: .value("Metric", stat.metric.rawValue),
            y: .value("Median", stat.median)
        )
        .foregroundStyle(AppTheme.leafGreen)
        .symbol(.diamond)
        .symbolSize(90)

        ForEach(Array(stat.outliers.enumerated()), id: \.offset) { _, value in
            PointMark(
                x: .value("Metric", stat.metric.rawValue),
                y: .value("Outlier", value)
            )
            .foregroundStyle(AppTheme.hotPinkDark)
            .symbolSize(40)
        }
    }
    .chartYScale(domain: 1...10)
    .chartYAxis { AxisMarks(position: .leading) }
}

@ViewBuilder
private func sleepHistogramChart(bins: [HistogramBin]) -> some View {
    Chart(bins) { bin in
        BarMark(
            x: .value("Sleep Hours", bin.label),
            y: .value("Count", bin.count)
        )
        .foregroundStyle(LinearGradient(colors: [AppTheme.hotPink.opacity(0.45), AppTheme.hotPinkDark], startPoint: .bottom, endPoint: .top))
    }
    .chartXAxis {
        AxisMarks(position: .bottom)
    }
    .chartYAxis { AxisMarks(position: .leading) }
}

@ViewBuilder
private func themedPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(12)
        .background(AppTheme.blush.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.stone.opacity(0.22), lineWidth: 1)
        )
}
