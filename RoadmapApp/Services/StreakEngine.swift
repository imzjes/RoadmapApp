import Foundation

/// Pulls a streak summary out of a roadmap's completed tasks. Headspace-style
/// — current + longest, no hearts, no XP, no escalating penalties.
struct StreakSummary: Equatable, Sendable {
    var current: Int = 0
    var longest: Int = 0
    var lastCompletedOn: Date?

    static let empty = StreakSummary()
}

struct StreakEngine {
    var calendar: Calendar = .current
    var now: Date = .now

    func summary(for roadmap: Roadmap) -> StreakSummary {
        let completedDays = Set(
            roadmap.orderedPhases
                .flatMap(\.orderedTasks)
                .compactMap(\.completedAt)
                .map { calendar.startOfDay(for: $0) }
        ).sorted()

        guard let last = completedDays.last else { return .empty }

        var longest = 0
        var run = 0
        var prev: Date?
        for day in completedDays {
            if let p = prev, calendar.dateComponents([.day], from: p, to: day).day == 1 {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            prev = day
        }

        var current = 0
        let today = calendar.startOfDay(for: now)
        let gap = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        if gap <= 1 {
            current = 1
            var cursor = last
            for day in completedDays.dropLast().reversed() {
                if calendar.dateComponents([.day], from: day, to: cursor).day == 1 {
                    current += 1
                    cursor = day
                } else {
                    break
                }
            }
        }

        return StreakSummary(current: current, longest: longest, lastCompletedOn: last)
    }
}
