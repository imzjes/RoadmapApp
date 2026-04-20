import Foundation
import SwiftData

/// Hardcoded fingerstyle-guitar roadmap used to drive UI development before
/// the Worker backend is live. Call `SeedData.installIfEmpty(_:)` from a
/// debug toggle or on first run in DEBUG builds.
enum SeedData {
    @MainActor
    static func installIfEmpty(_ store: RoadmapStore = .shared) {
        guard store.allRoadmaps().isEmpty else { return }
        let roadmap = makeGuitarRoadmap()
        store.insertRoadmap(roadmap)
        store.activate(roadmap)
        ScheduleEngine(daysPerWeek: 4).assignDates(to: roadmap)
        try? store.mainContext.save()
    }

    static func makeGuitarRoadmap() -> Roadmap {
        let roadmap = Roadmap(
            goal: "Play fingerstyle guitar",
            title: "Fingerstyle Guitar — 8 Weeks",
            summary: "A four-phase plan from basic posture to a short fingerstyle arrangement.",
            level: "beginner",
            status: .active
        )
        roadmap.phases = [
            phase1(),
            phase2(),
            phase3(),
            phase4()
        ]
        for (i, phase) in (roadmap.phases ?? []).enumerated() {
            phase.orderIndex = i
            phase.roadmap = roadmap
        }
        return roadmap
    }

    // MARK: Phases

    private static func phase1() -> Phase {
        let phase = Phase(
            title: "Foundations",
            summary: "Posture, right-hand anchoring, open chords, metronome basics.",
            targetWeeks: 2
        )
        phase.tasks = [
            task("Sit correctly, hold the guitar", minutes: 20, order: 0,
                 detail: "Classical posture; elbow just off the body; wrist straight.",
                 resources: [
                    res("Proper Classical Guitar Posture", "https://www.youtube.com/watch?v=dPt9QAekcb4", kind: .youtube)
                 ]),
            task("Anchor right-hand thumb", minutes: 20, order: 1,
                 detail: "Thumb plays bass strings (6/5/4); i-m-a for 3/2/1."),
            task("C, G, D, Em, Am open chords", minutes: 30, order: 2,
                 detail: "Clean transitions, one second between changes.",
                 resources: [
                    res("Open Chord Primer", "https://www.justinguitar.com/classes/beginner-open-chords", kind: .article)
                 ]),
            task("60 BPM down-strums", minutes: 15, order: 3,
                 detail: "Metronome on 2 & 4.")
        ]
        linkTasks(phase)
        return phase
    }

    private static func phase2() -> Phase {
        let phase = Phase(
            title: "Fingerpicking patterns",
            summary: "Travis picking, arpeggios, p-i-m-a coordination.",
            targetWeeks: 2
        )
        phase.tasks = [
            task("p-i-m-a arpeggio on C", minutes: 20, order: 0,
                 detail: "Thumb on 5th, index/middle/ring on 3/2/1."),
            task("Travis picking alternating bass", minutes: 25, order: 1,
                 detail: "Thumb alternates 5–4 on C; 6–4 on G."),
            task("Chord transitions while picking", minutes: 25, order: 2),
            task("Record yourself at 70 BPM", minutes: 15, order: 3)
        ]
        linkTasks(phase)
        return phase
    }

    private static func phase3() -> Phase {
        let phase = Phase(
            title: "Your first arrangement",
            summary: "Learn a short fingerstyle piece end-to-end.",
            targetWeeks: 2
        )
        phase.tasks = [
            task("Pick a simple tune", minutes: 30, order: 0,
                 detail: "House of the Rising Sun, Dust in the Wind (A-section), or similar.",
                 resources: [
                    res("Dust in the Wind tutorial", "https://www.youtube.com/watch?v=tH2w6Oxx0kQ", kind: .youtube)
                 ]),
            task("Learn the first 8 bars", minutes: 40, order: 1),
            task("Memorize without the score", minutes: 30, order: 2),
            task("Play along at ¾ speed", minutes: 25, order: 3)
        ]
        linkTasks(phase)
        return phase
    }

    private static func phase4() -> Phase {
        let phase = Phase(
            title: "Perform it",
            summary: "Clean execution, dynamics, record a take.",
            targetWeeks: 2
        )
        phase.tasks = [
            task("Play end-to-end at full tempo", minutes: 40, order: 0),
            task("Add dynamics (soft intro, loud bridge)", minutes: 30, order: 1),
            task("Record and critique", minutes: 30, order: 2),
            task("Show someone", minutes: 15, order: 3,
                 detail: "Friend, family member, or voice memo sent to yourself.")
        ]
        linkTasks(phase)
        return phase
    }

    // MARK: Helpers

    private static func task(
        _ title: String,
        minutes: Int,
        order: Int,
        detail: String? = nil,
        resources: [Resource] = []
    ) -> LearningTask {
        let t = LearningTask(title: title, detail: detail, orderIndex: order, durationMinutes: minutes)
        t.resources = resources
        return t
    }

    private static func res(_ title: String, _ url: String, kind: ResourceKind, author: String? = nil) -> Resource {
        Resource(title: title, urlString: url, kind: kind, author: author)
    }

    private static func linkTasks(_ phase: Phase) {
        for task in phase.tasks ?? [] {
            task.phase = phase
            for resource in task.resources ?? [] {
                resource.task = task
            }
        }
    }
}
