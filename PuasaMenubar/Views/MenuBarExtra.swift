import SwiftUI
import AppKit

struct MenuBarExtraView: View {
    @StateObject private var viewModel = PrayerTimesViewModel()
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.accentColor)
                Text("Prayer Times")
                    .font(.headline)
                Spacer()
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading || locationManager.isRequestingPermission)
            }

            Divider()

            locationStatusView

            Divider()

            // Content
            if !locationManager.hasPermission {
                permissionView
            } else if viewModel.isLoading && viewModel.prayerTimesData == nil {
                loadingView
            } else if viewModel.errorMessage != nil, viewModel.prayerTimesData == nil {
                errorView
            } else {
                contentView
            }
        }
        .padding(12)
        .frame(width: 280)
        .onAppear {
            setupLocation()
        }
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

    // MARK: - Location Status

    private var locationStatusView: some View {
        HStack(spacing: 6) {
            Image(systemName: locationManager.hasPermission ? "location.fill" : "location.slash")
                .font(.caption)
                .foregroundColor(locationManager.hasPermission ? .accentColor : .secondary)

            if locationManager.isRequestingPermission {
                Text("Getting location…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if locationManager.hasPermission {
                Text(locationManager.cityName == "Unknown" ? "Locating…" : "\(locationManager.cityName), \(locationManager.countryName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                Text("Location not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Permission View

    private var permissionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.circle")
                .font(.system(size: 36))
                .foregroundColor(.accentColor)

            Text("Location Access Needed")
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Allow location access to get accurate prayer times for your area.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Location") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Button("Allow Location Access") {
                    locationManager.requestPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(locationManager.isRequestingPermission)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Loading prayer times…")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }

    private var errorView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(viewModel.errorMessage ?? "Error")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: fetchByLocation)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Content

    private var contentView: some View {
        Group {
            // Next Prayer
            VStack(spacing: 4) {
                Text("Next Prayer")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack {
                    if let nextPrayer = viewModel.nextPrayer {
                        Text(nextPrayer)
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        if let timeUntil = viewModel.timeUntilNextPrayer {
                            Text("in \(timeUntil)")
                                .font(.caption)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)

            Divider()

            // Prayer Times List
            if let timings = viewModel.prayerTimesData?.timings {
                VStack(spacing: 5) {
                    ForEach(timings.allPrayerTimes()) { prayer in
                        HStack {
                            Text(prayer.icon)
                                .frame(width: 20)
                            Text(prayer.name)
                                .font(.caption)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            Text(prayer.time)
                                .font(.caption)
                                .monospacedDigit()
                                .fontWeight(prayer.name == viewModel.nextPrayer ? .bold : .regular)
                                .foregroundColor(prayer.name == viewModel.nextPrayer ? .accentColor : .primary)
                            if prayer.name == viewModel.nextPrayer {
                                Image(systemName: "circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }

            Divider()

            // Footer
            if let dateInfo = viewModel.prayerTimesData?.date {
                HStack {
                    if let hijri = dateInfo.hijri {
                        Text("📅 \(hijri.day) \(hijri.month.en) \(hijri.year)")
                            .font(.caption2)
                    }
                    Spacer()
                    if let gregorian = dateInfo.gregorian {
                        Text("🗓️ \(gregorian.day) \(gregorian.month.en) \(gregorian.year)")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.secondary)
            }

            HStack {
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption2)
            }
        }
    }

    // MARK: - Helpers

    private func setupLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestPermission()
        case .authorized, .authorizedAlways:
            locationManager.startUpdatingLocation()
            if viewModel.prayerTimesData == nil {
                fetchByLocation()
            }
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
