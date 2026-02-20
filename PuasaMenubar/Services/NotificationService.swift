import Foundation
import UserNotifications

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isNotificationEnabled: Bool = false
    @Published var hasPermission: Bool = false
    
    private let center = UNUserNotificationCenter.current()
    
    // Track notified prayers to avoid duplicate notifications
    private var notifiedPrayers: Set<String> = []
    
    // Prayer icon mapping
    private let prayerIcons: [String: String] = [
        "Fajr": "🌅",
        "Sunrise": "🌄",
        "Dhuhr": "☀️",
        "Asr": "🌤️",
        "Maghrib": "🌆",
        "Isha": "🌙",
        "Imsak": "🤲"
    ]
    
    override init() {
        super.init()
        center.delegate = self
        checkNotificationStatus()
    }
    
    // MARK: - Permission
    
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                self?.isNotificationEnabled = granted
                if granted {
                    Task { @MainActor in
                        self?.scheduleDailyNotifications()
                    }
                }
            }
        }
    }
    
    func checkNotificationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
                self?.isNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func toggleNotifications(enabled: Bool) {
        isNotificationEnabled = enabled
        if enabled && hasPermission {
            scheduleDailyNotifications()
        } else {
            center.removeAllPendingNotificationRequests()
        }
    }
    
    // MARK: - Send Notification
    
    func sendPrayerNotification(prayerName: String, prayerTime: String) {
        let icon = prayerIcons[prayerName] ?? "🕌"
        
        let content = UNMutableNotificationContent()
        content.title = "Prayer Time: \(prayerName) \(icon)"
        content.body = "It's time for \(prayerName) prayer (\(prayerTime))"
        content.sound = .default
        content.categoryIdentifier = "prayer_time"
        content.threadIdentifier = "prayer_times"
        
        let request = UNNotificationRequest(
            identifier: "prayer_\(prayerName)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - Schedule Daily Notifications
    
    func scheduleDailyNotifications() {
        center.removeAllPendingNotificationRequests()
        
        guard let prayerTimesData = PrayerTimesViewModel.shared.prayerTimesData else { return }
        let timings = prayerTimesData.timings
        
        for prayer in timings.allPrayerTimes() {
            schedulePrayerNotification(prayer: prayer)
        }
    }
    
    private func schedulePrayerNotification(prayer: PrayerTime) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let time = timeFormatter.date(from: prayer.time) else { return }
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = calendar.component(.hour, from: time)
        components.minute = calendar.component(.minute, from: time)
        components.second = 0
        
        var triggerDate = calendar.date(from: components)
        
        // If the time has passed today, schedule for tomorrow
        if let triggerDateUnwrapped = triggerDate, triggerDateUnwrapped <= Date() {
            triggerDate = calendar.date(byAdding: .day, value: 1, to: triggerDateUnwrapped)
            if let newTriggerDate = triggerDate {
                components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: newTriggerDate)
            }
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let icon = prayerIcons[prayer.name] ?? "🕌"
        let content = UNMutableNotificationContent()
        content.title = "Prayer Time: \(prayer.name) \(icon)"
        content.body = "It's time for \(prayer.name) prayer"
        content.sound = .default
        content.categoryIdentifier = "prayer_time"
        content.threadIdentifier = "prayer_times"
        
        let request = UNNotificationRequest(
            identifier: "prayer_\(prayer.name)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling \(prayer.name) notification: \(error)")
            }
        }
    }
    
    // MARK: - Reset Daily Notifications
    
    func resetNotifiedPrayers() {
        notifiedPrayers.removeAll()
    }
    
    func hasNotifiedPrayer(_ prayerName: String) -> Bool {
        return notifiedPrayers.contains(prayerName)
    }
    
    func markPrayerAsNotified(_ prayerName: String) {
        notifiedPrayers.insert(prayerName)
    }
}

// MARK: - UNUserNotificationCenterDelegate

@MainActor
extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        completionHandler()
    }
}
