import Foundation

/// Lightweight scheduler: given a cadence (days per week) and a start date,
/// spreads a phase's tasks across upcoming cadence days.
struct ScheduleEngine {
    var daysPerWeek: Int = 5
    var startDate: Date = .now
    var calendar: Calendar = .current

    /// Returns the N upcoming dates matching the cadence, starting from
    /// `startDate`. Cadence is "spread evenly across the week" — e.g. 3/wk
    /// emits Mon/Wed/Fri-ish, 5/wk is weekdays, 7/wk is every day.
    func dates(count: Int) -> [Date] {
        guard daysPerWeek > 0, count > 0 else { return [] }
        let weekdayOffsets = cadenceOffsets(for: daysPerWeek)
        var result: [Date] = []
        var week = 0
        while result.count < count {
            for offset in weekdayOffsets {
                if let d = calendar.date(byAdding: .day, value: week * 7 + offset, to: startDate) {
                    result.append(calendar.startOfDay(for: d))
                    if result.count == count { return result }
                }
            }
            week += 1
        }
        return result
    }

    /// Assigns `scheduledDate` across all tasks of the roadmap in order.
    /// Does not persist — caller is responsible for saving the context.
    func assignDates(to roadmap: Roadmap) {
        let tasks = roadmap.orderedPhases.flatMap(\.orderedTasks)
        let slots = dates(count: tasks.count)
        for (task, date) in zip(tasks, slots) {
            task.scheduledDate = date
        }
    }

    private func cadenceOffsets(for perWeek: Int) -> [Int] {
        let n = min(max(perWeek, 1), 7)
        let step = 7.0 / Double(n)
        return (0..<n).map { Int(Double($0) * step) }
    }
}
