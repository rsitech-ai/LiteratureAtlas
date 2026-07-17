import SwiftUI

#if os(macOS)
import AppKit

@available(macOS 26, *)
struct PointerTrackingView: NSViewRepresentable {
    var onMove: (CGPoint) -> Void
    var onExit: () -> Void = {}

    func makeNSView(context: Context) -> TrackingNSView {
        let view = TrackingNSView()
        view.onMove = onMove
        view.onExit = onExit
        return view
    }

    func updateNSView(_ nsView: TrackingNSView, context: Context) {
        nsView.onMove = onMove
        nsView.onExit = onExit
    }
}

@available(macOS 26, *)
final class TrackingNSView: NSView {
    var onMove: ((CGPoint) -> Void)?
    var onExit: (() -> Void)?

    private var trackingAreaRef: NSTrackingArea?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let options: NSTrackingArea.Options = [
            .activeInKeyWindow,
            .mouseMoved,
            .mouseEnteredAndExited,
            .inVisibleRect
        ]
        let area = NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let location = convert(event.locationInWindow, from: nil)
        let point = CGPoint(x: location.x, y: location.y)
        DispatchQueue.main.async { [weak self] in
            self?.onMove?(point)
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        DispatchQueue.main.async { [weak self] in
            self?.onExit?()
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}
#endif
