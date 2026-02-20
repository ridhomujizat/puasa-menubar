import SwiftUI
import AppKit

struct MenuBarExtraView: View {
    @StateObject private var viewModel = PrayerTimesViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationService = NotificationService.shared

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                locationManager: locationManager,
                isLoading: viewModel.isLoading,
                onRefresh: refresh
            )

            if !locationManager.hasPermission {
                PermissionView(locationManager: locationManager)
            } else if viewModel.isLoading && viewModel.prayerTimesData == nil {
                LoadingView()
            } else if viewModel.errorMessage != nil && viewModel.prayerTimesData == nil {
                ErrorStateView(message: viewModel.errorMessage ?? "Unknown error", onRetry: fetchByLocation)
            } else {
                MainContentView(viewModel: viewModel, notificationService: notificationService)
            }
        }
        .frame(width: 300)
        .background(.thinMaterial)
        .tint(.ramadanGreen)
        .onAppear(perform: setupLocation)
        .onChange(of: locationManager.location) { _, newLocation in
            guard newLocation != nil, viewModel.prayerTimesData == nil else { return }
            fetchByLocation()
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .authorized || status == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }
    }

    private func setupLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestPermission()
        case .authorized, .authorizedAlways:
            locationManager.startUpdatingLocation()
            if viewModel.prayerTimesData == nil { fetchByLocation() }
        default:
            break
        }
    }

    private func fetchByLocation() {
        guard let lat = locationManager.latitude, let lon = locationManager.longitude else { return }
        viewModel.fetchPrayerTimes(latitude: lat, longitude: lon)
    }

    private func refresh() {
        locationManager.startUpdatingLocation()
        fetchByLocation()
    }
}

// MARK: - Header

private struct HeaderView: View {
    let locationManager: LocationManager
    let isLoading: Bool
    let onRefresh: () -> Void

    private var locationLabel: String {
        if locationManager.isRequestingPermission { return "Locating…" }
        if locationManager.hasPermission && locationManager.cityName != "Unknown" {
            return "\(locationManager.cityName), \(locationManager.countryName)"
        }
        return "Prayer Times"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .foregroundStyle(.tint)
                .font(.system(size: 14, weight: .semibold))

            Text(locationLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: isLoading ? "arrow.clockwise" : "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(
                        isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: isLoading
                    )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Button(action: { NSApp.terminate(nil) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Next Prayer Hero

private struct NextPrayerCard: View {
    let name: String
    let time: String
    let countdown: String

    var body: some View {
        VStack(spacing: 2) {
            Text("Next Prayer")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(0.5)

            Text(name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(time)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text(countdown)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.ramadanGreen)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.ramadanGreen.opacity(0.08), in: .rect(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Prayer Row

private struct PrayerRow: View {
    let prayer: PrayerTime
    let isNext: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(prayer.icon)
                .font(.system(size: 14))
                .frame(width: 22)

            Text(prayer.name)
                .font(.system(size: 13, weight: isNext ? .semibold : .regular))
                .foregroundStyle(isNext ? Color.primary : Color.secondary)

            Spacer()

            Text(prayer.time)
                .font(.system(size: 13, weight: isNext ? .semibold : .regular).monospacedDigit())
                .foregroundStyle(isNext ? Color.ramadanGreen : Color.secondary)

            Circle()
                .fill(Color.ramadanGreen)
                .frame(width: 6, height: 6)
                .opacity(isNext ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.ramadanGreen.opacity(isNext ? 0.04 : 0), in: .rect(cornerRadius: 8))
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.2), value: isNext)
    }
}

// MARK: - Date Footer

private struct DateFooterView: View {
    let dateInfo: DateInfo

    var body: some View {
        HStack {
            if let hijri = dateInfo.hijri {
                Text("\(hijri.day) \(hijri.month.en) \(hijri.year) AH")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let gregorian = dateInfo.gregorian {
                Text("\(gregorian.day) \(gregorian.month.en) \(gregorian.year)")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.system(size: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Notification Settings

private struct NotificationSettingsView: View {
    @ObservedObject var notificationService: NotificationService

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: notificationService.isNotificationEnabled ? "bell.fill" : "bell.slash.fill")
                .foregroundStyle(notificationService.isNotificationEnabled ? Color.ramadanGreen : .secondary)
                .font(.system(size: 12))

            Text("Notifications")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Toggle("", isOn: $notificationService.isNotificationEnabled)
                .onChange(of: notificationService.isNotificationEnabled) { _, newValue in
                    notificationService.toggleNotifications(enabled: newValue)
                }
                .toggleStyle(.switch)
                .scaleEffect(0.8)

            if !notificationService.hasPermission {
                Button("Allow") {
                    notificationService.requestPermission()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.ramadanGreen.opacity(0.04), in: .rect(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

// MARK: - Main Content

private struct MainContentView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel
    @ObservedObject var notificationService: NotificationService

    var body: some View {
        VStack(spacing: 0) {
            if let nextPrayer = viewModel.nextPrayer,
               let countdown = viewModel.timeUntilNextPrayer,
               let timings = viewModel.prayerTimesData?.timings,
               let prayerTime = timings.allPrayerTimes().first(where: { $0.name == nextPrayer }) {
                NextPrayerCard(
                    name: nextPrayer,
                    time: prayerTime.time,
                    countdown: countdown
                )
            }

            if let timings = viewModel.prayerTimesData?.timings {
                VStack(spacing: 2) {
                    ForEach(timings.allPrayerTimes()) { prayer in
                        PrayerRow(prayer: prayer, isNext: prayer.name == viewModel.nextPrayer)
                    }
                }
                .padding(.bottom, 6)
            }

            Divider()
                .padding(.horizontal, 16)

            NotificationSettingsView(notificationService: notificationService)

            if let dateInfo = viewModel.prayerTimesData?.date {
                DateFooterView(dateInfo: dateInfo)
            }
        }
    }
}

// MARK: - Permission View

private struct PermissionView: View {
    let locationManager: LocationManager

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.tint)

            Text("Location Access Needed")
                .font(.system(size: 13, weight: .semibold))

            Text("Required to calculate accurate prayer times for your area.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Location") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button("Allow Location") {
                    locationManager.requestPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(locationManager.isRequestingPermission)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Fetching prayer times…")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Error View

private struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}
