import SwiftUI
import UIKit

/// Custom gesture recognizer tuned for quick tap/click activation without requiring head or gaze alignment.
final class AccessibilityClickGestureRecognizer: UIGestureRecognizer {
    private enum StateMachine {
        case possible
        case recognized
        case failed
    }

    private var stateMachine: StateMachine = .possible
    private var initialTouchTimestamp: TimeInterval?

    /// Maximum interval (in seconds) between touch begin/end to qualify as a click.
    private let maxClickDuration: TimeInterval = 0.35
    /// Maximum finger movement before we consider it a drag instead of a click (points).
    private let maxTranslation: CGFloat = 30

    private var startingLocation: CGPoint = .zero

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard touches.count == 1, let touch = touches.first else {
            state = .failed
            return
        }
        startingLocation = touch.location(in: view)
        initialTouchTimestamp = touch.timestamp
        stateMachine = .possible
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        let distance = hypot(location.x - startingLocation.x, location.y - startingLocation.y)
        if distance > maxTranslation {
            stateMachine = .failed
            state = .failed
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard stateMachine != .failed,
              let began = initialTouchTimestamp,
              let touch = touches.first else {
            state = .failed
            return
        }

        let duration = touch.timestamp - began
        if duration <= maxClickDuration {
            stateMachine = .recognized
            state = .recognized
        } else {
            state = .failed
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        stateMachine = .failed
        state = .cancelled
    }

    override func reset() {
        stateMachine = .possible
        initialTouchTimestamp = nil
        startingLocation = .zero
    }
}

/// SwiftUI wrapper for our custom gesture recognizer.
struct AccessibilityClickGesture: UIViewRepresentable {
    let onActivate: () -> Void

    func makeUIView(context: Context) -> GesturePassthroughView {
        let view = GesturePassthroughView()
        let recognizer = AccessibilityClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        recognizer.delegate = context.coordinator
        view.addGestureRecognizer(recognizer)
        view.accessibilityTraits.insert(.button)
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Spatial scan trigger"
        view.accessibilityHint = "Double tap or perform a quick click to scan the scene."
        return view
    }

    func updateUIView(_ uiView: GesturePassthroughView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onActivate: onActivate)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let onActivate: () -> Void

        init(onActivate: @escaping () -> Void) {
            self.onActivate = onActivate
        }

        @objc func handleClick(_ recognizer: AccessibilityClickGestureRecognizer) {
            guard recognizer.state == .recognized else { return }
            onActivate()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            true
        }
    }
}

/// Transparent view that lets underlying SwiftUI content continue receiving gaze/hand gestures while also hosting UIKit gestures.
final class GesturePassthroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        true
    }
}
