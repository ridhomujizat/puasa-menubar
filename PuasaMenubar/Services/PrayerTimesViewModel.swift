import Foundation

@MainActor
class PrayerTimesViewModel: ObservableObject {
    @Published var prayerTimesData: PrayerTimesData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var nextPrayer: String?
    @Published var timeUntilNextPrayer: String?
    @Published var currentDate: Date = Date()

    static let shared = PrayerTimesViewModel()
    
    private let apiService = APIService.shared
    private let notificationService = NotificationService.shared
    private var updateTimer: Timer?
    private var nextPrayerDate: Date?
    private var lastNotifiedPrayer: String?

    // Cached once — DateFormatter is expensive to create
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    func fetchPrayerTimes(latitude: Double, longitude: Double) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let data = try await apiService.fetchPrayerTimes(
                    latitude: latitude,
                    longitude: longitude,
                    date: currentDate
                )
                prayerTimesData = data
                timeFormatter.timeZone = TimeZone(identifier: data.timezone ?? "Asia/Jakarta")
                computeNextPrayer()
                startTimer()
            } catch {
                errorMessage = error.localizedDescription
                print("Error fetching prayer times: \(error)")
            }
            isLoading = false
        }
    }

    func fetchPrayerTimesByCity(city: String, country: String) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let data = try await apiService.fetchPrayerTimesByCity(
                    city: city,
                    country: country,
                    date: currentDate
                )
                prayerTimesData = data
                timeFormatter.timeZone = TimeZone(identifier: data.timezone ?? "Asia/Jakarta")
                computeNextPrayer()
                startTimer()
            } catch {
                errorMessage = "Failed: \(error.localizedDescription)"
                print("Error fetching prayer times: \(error)")
            }
            isLoading = false
        }
    }

    // Called once when data loads (or when the next prayer changes).
    // Parses prayer time strings → concrete Date objects and finds the soonest upcoming one.
    private func computeNextPrayer() {
        guard let timings = prayerTimesData?.timings else { return }

        let now = Date()
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)

        var soonestName: String?
        var soonestDate: Date?

        for prayer in timings.allPrayerTimes() {
            guard let parsed = timeFormatter.date(from: prayer.time) else { continue }

            var components = todayComponents
            components.hour   = calendar.component(.hour,   from: parsed)
            components.minute = calendar.component(.minute, from: parsed)
            components.second = 0

            guard var prayerDate = calendar.date(from: components) else { continue }

            if prayerDate <= now {
                prayerDate = prayerDate.addingTimeInterval(86400) // tomorrow
            }

            if soonestDate == nil || prayerDate < soonestDate! {
                soonestDate = prayerDate
                soonestName = prayer.name
            }
        }

        nextPrayer = soonestName
        nextPrayerDate = soonestDate
        tickCountdown()
    }

    // Called every second — only arithmetic, no parsing or allocation.
    private func tickCountdown() {
        guard let target = nextPrayerDate else { return }

        let remaining = max(0, target.timeIntervalSinceNow)
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60
        let s = Int(remaining) % 60
        timeUntilNextPrayer = String(format: "%02d:%02d:%02d", h, m, s)

        // When the countdown hits zero, send notification and re-compute
        if remaining == 0 {
            sendNotificationIfNeeded()
            computeNextPrayer()
        }
    }
    
    private func sendNotificationIfNeeded() {
        guard notificationService.isNotificationEnabled,
              let prayer = nextPrayer,
              prayer != lastNotifiedPrayer,
              let timings = prayerTimesData?.timings,
              let prayerTime = timings.allPrayerTimes().first(where: { $0.name == prayer })?.time
        else { return }
        
        notificationService.sendPrayerNotification(prayerName: prayer, prayerTime: prayerTime)
        lastNotifiedPrayer = prayer
    }

    private func startTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickCountdown()
            }
        }
    }

    func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
