import EventKit
import EventKitUI
import SwiftUI
import UIKit

/// Presents `EKEventEditViewController` so the user can optionally add a
/// task to their system calendar without the app itself requesting calendar
/// permission. Bulk scheduling is deferred to v1.1.
struct AddToCalendarSheet: UIViewControllerRepresentable {
    var task: LearningTask
    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = task.title
        event.notes = task.detail
        let start = task.scheduledDate ?? Date()
        event.startDate = start
        event.endDate = start.addingTimeInterval(TimeInterval(task.durationMinutes) * 60)

        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true) { [onDismiss] in onDismiss() }
        }
    }
}
