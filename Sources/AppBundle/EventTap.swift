import AppKit
import Common
@preconcurrency import CoreGraphics

nonisolated(unsafe) private var eventTap: CFMachPort?
nonisolated(unsafe) private var runLoopSource: CFRunLoopSource?

func initEventTap() {
    let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
    guard let tap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: eventTapCallback,
        userInfo: nil,
    ) else {
        die("Failed to create event tap")
    }

    eventTap = tap
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

    if let source = runLoopSource {
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
}

private func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    guard type == .keyDown || type == .keyUp else {
        return Unmanaged.passUnretained(event)
    }

    // Extract modifiers from event flags
    // Note: We directly map raw values to preserve device-dependent flags (e.g. .lCommand vs .rCommand).
    // NSEvent(cgEvent:) strips these into generic flags, breaking bindings like 'mod = rcmd'.
    let modifiers = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))

    let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
    let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

    // Perform matching on MainActor
    if Thread.isMainThread {
        let shouldSwallow = MainActor.assumeIsolated {
            handleEventOnMainThread(type: type, keyCode: keyCode, modifiers: modifiers, isRepeat: isRepeat)
        }
        return shouldSwallow ? nil : Unmanaged.passUnretained(event)
    } else {
        return Unmanaged.passUnretained(event)
    }
}
