import Foundation

// MARK: - API Response Models
struct PrayerTimesResponse: Codable {
    let code: Int
    let status: String
    let data: PrayerTimesData
}

struct PrayerTimesData: Codable {
    let timings: Timings
    let date: DateInfo
    let meta: Meta?
    let timezone: String?
    
    enum CodingKeys: String, CodingKey {
        case timings
        case date
        case meta
        case timezone
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timings = try container.decode(Timings.self, forKey: .timings)
        date = try container.decode(DateInfo.self, forKey: .date)
        meta = try container.decodeIfPresent(Meta.self, forKey: .meta)
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
    }
}

struct Timings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Sunset: String
    let Maghrib: String
    let Isha: String
    let Imsak: String
    let Midnight: String
    let Firstthird: String?
    let Lastthird: String?

    enum CodingKeys: String, CodingKey {
        case Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha, Imsak, Midnight
        case Firstthird, Lastthird
    }

    func allPrayerTimes() -> [PrayerTime] {
        return [
            PrayerTime(name: "Fajr", time: Fajr, icon: "🌅"),
            PrayerTime(name: "Sunrise", time: Sunrise, icon: "🌄"),
            PrayerTime(name: "Dhuhr", time: Dhuhr, icon: "☀️"),
            PrayerTime(name: "Asr", time: Asr, icon: "🌤️"),
            PrayerTime(name: "Sunset", time: Sunset, icon: "🌅"),
            PrayerTime(name: "Maghrib", time: Maghrib, icon: "🌆"),
            PrayerTime(name: "Isha", time: Isha, icon: "🌙"),
            PrayerTime(name: "Imsak", time: Imsak, icon: "🤲")
        ]
    }
}

struct PrayerTime: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let time: String
    let icon: String

    var formattedTime: String {
        return time
    }
}

struct DateInfo: Codable {
    let readable: String
    let date: String?
    let timestamp: String?
    let hijri: HijriDate?
    let gregorian: GregorianDate?
    
    enum CodingKeys: String, CodingKey {
        case readable
        case date
        case timestamp
        case hijri
        case gregorian
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        readable = try container.decode(String.self, forKey: .readable)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        hijri = try container.decodeIfPresent(HijriDate.self, forKey: .hijri)
        gregorian = try container.decodeIfPresent(GregorianDate.self, forKey: .gregorian)
    }
}

struct HijriDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: WeekdayInfo
    let month: MonthInfo
    let year: String
    let designation: Designation
}

struct GregorianDate: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: WeekdayInfo
    let month: GregorianMonthInfo
    let year: String
    let designation: Designation
}

struct WeekdayInfo: Codable {
    let en: String
    let ar: String?
}

struct MonthInfo: Codable {
    let number: Int
    let en: String
    let ar: String
    let days: Int?
}

struct GregorianMonthInfo: Codable {
    let number: Int
    let en: String
    let days: Int?
}

struct Designation: Codable {
    let abbreviated: String
    let expanded: String
}

struct Meta: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let method: Method
    let latitudeAdjustmentMethod: String
    let midnightMode: String
    let school: String
    let offset: Offset
}

struct Method: Codable {
    let id: Int
    let name: String
    let params: MethodParams
}

struct MethodParams: Codable {
    let Fajr: Double
    let Isha: Double
}

struct Offset: Codable {
    let Imsak: Int
    let Fajr: Int
    let Sunrise: Int
    let Dhuhr: Int
    let Asr: Int
    let Maghrib: Int
    let Sunset: Int
    let Isha: Int
    let Midnight: Int
}
