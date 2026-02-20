import SwiftUI

struct PrayerTimeRow: View {
    let prayerTime: PrayerTime
    let isNextPrayer: Bool
    
    var body: some View {
        HStack {
            Text(prayerTime.icon)
                .font(.title3)
                .frame(width: 30)
            
            Text(prayerTime.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(prayerTime.formattedTime)
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundColor(isNextPrayer ? .white : .secondary)
            
            if isNextPrayer {
                Image(systemName: "circle.fill")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isNextPrayer ? Color.accentColor : Color.gray.opacity(0.1))
        )
    }
}
