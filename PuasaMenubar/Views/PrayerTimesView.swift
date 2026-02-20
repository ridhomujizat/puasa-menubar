import SwiftUI

struct PrayerTimesView: View {
    @StateObject private var viewModel = PrayerTimesViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: 20) {
                    if locationManager.hasPermission {
                        mainContent
                    } else {
                        permissionView
                    }
                }
                .padding()
            }
            .navigationTitle("Prayer Times")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if locationManager.hasPermission {
                        Button(action: {
                            if let lat = locationManager.latitude, let lon = locationManager.longitude {
                                viewModel.fetchPrayerTimes(latitude: lat, longitude: lon)
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                .animation(viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .alert("Location Permission Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings", role: .cancel) {
                    if let settingsUrl = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Location") {
                        NSWorkspace.shared.open(settingsUrl)
                    }
                }
                Button("Maybe Later", role: .destructive) { }
            } message: {
                Text("This app needs your location to show accurate prayer times for your area.")
            }
            .onAppear {
                checkLocationPermission()
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                locationHeader
                nextPrayerCard
                dateInfo
                prayerTimesList
                
                if viewModel.isLoading {
                    ProgressView("Loading prayer times...")
                        .padding()
                }
                
                if let error = viewModel.errorMessage {
                    ErrorView(message: error, onRetry: retryFetch)
                }
            }
        }
    }
    
    private var locationHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.accentColor)
                Text(locationManager.cityName)
                    .font(.headline)
                if !locationManager.countryName.isEmpty && locationManager.countryName != "Unknown" {
                    Text(", \(locationManager.countryName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let lat = locationManager.latitude, let lon = locationManager.longitude {
                Text(String(format: "%.4f, %.4f", lat, lon))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.textBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var nextPrayerCard: some View {
        VStack(spacing: 8) {
            Text("Next Prayer")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let nextPrayer = viewModel.nextPrayer {
                Text(nextPrayer)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
            }
            
            if let timeUntil = viewModel.timeUntilNextPrayer {
                Text("in \(timeUntil)")
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var dateInfo: some View {
        Group {
            if let dateInfo = viewModel.prayerTimesData?.date {
                VStack(spacing: 4) {
                    Text(dateInfo.readable)
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        if let hijri = dateInfo.hijri {
                            Text("📅 \(hijri.day) \(hijri.month.en) \(hijri.year) AH")
                        }
                        Text("•")
                        if let gregorian = dateInfo.gregorian {
                            Text("\(gregorian.day) \(gregorian.month.en) \(gregorian.year)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.textBackgroundColor))
                .cornerRadius(12)
            }
        }
    }
    
    private var prayerTimesList: some View {
        VStack(spacing: 8) {
            if let timings = viewModel.prayerTimesData?.timings {
                ForEach(timings.allPrayerTimes()) { prayer in
                    PrayerTimeRow(
                        prayerTime: prayer,
                        isNextPrayer: prayer.name == viewModel.nextPrayer
                    )
                }
            }
        }
    }
    
    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Location Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please enable location access to see prayer times for your area")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                locationManager.requestPermission()
            }) {
                Text("Grant Permission")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            
            Button(action: {
                showingPermissionAlert = true
            }) {
                Text("Open Settings")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
    }
    
    private func checkLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestPermission()
        case .denied, .restricted:
            showingPermissionAlert = true
        case .authorized, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    private func retryFetch() {
        if let lat = locationManager.latitude, let lon = locationManager.longitude {
            viewModel.fetchPrayerTimes(latitude: lat, longitude: lon)
        }
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                Text("Retry")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.textBackgroundColor))
        .cornerRadius(12)
    }
}
