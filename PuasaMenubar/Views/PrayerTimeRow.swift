import SwiftUI

struct PrayerTimeRow: View {
    let prayerTime: PrayerTime
    let isNextPrayer: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(prayerTime.icon)
                .font(.system(size: 14))
                .frame(width: 22)

            Text(prayerTime.name)
                .font(.system(size: 13, weight: isNextPrayer ? .semibold : .regular))
                .foregroundStyle(isNextPrayer ? Color.primary : Color.secondary)

            Spacer()

            Text(prayerTime.formattedTime)
                .font(.system(size: 13, weight: isNextPrayer ? .semibold : .regular).monospacedDigit())
                .foregroundStyle(isNextPrayer ? Color.ramadanGreen : Color.secondary)

            Circle()
                .fill(Color.ramadanGreen)
                .frame(width: 6, height: 6)
                .opacity(isNextPrayer ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.ramadanGreen.opacity(isNextPrayer ? 0.06 : 0), in: .rect(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.2), value: isNextPrayer)
    }
}
