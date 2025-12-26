import AppKit
import Common
import HotKey
import TOMLKit
@preconcurrency import CoreGraphics

@MainActor private var activeBindings: [UInt32: [HotkeyBinding]] = [:]
@MainActor private var repeatingTasks: [UInt32: Task<Void, Never>] = [:]

@MainActor func resetHotKeys() {
    activeBindings = [:]
    for task in repeatingTasks.values {
        task.cancel()
    }
    repeatingTasks = [:]
}

@MainActor var activeMode: String? = mainModeId
@MainActor func activateMode(_ targetMode: String?) async throws {
    if let bindings = targetMode.flatMap({ config.modes[$0] })?.bindings.values {
        activeBindings = Dictionary(grouping: bindings, by: { $0.keyCode.carbonKeyCode })
            .mapValues { bindings in
                bindings.sorted { $0.modifiers.rawValue.nonzeroBitCount > $1.modifiers.rawValue.nonzeroBitCount }
            }
    } else {
        activeBindings = [:]
    }

    // Cleanup repeating tasks for bindings that are no longer active
    for (keyCode, task) in repeatingTasks {
        if activeBindings[keyCode] == nil {
            task.cancel()
            repeatingTasks[keyCode] = nil
        }
    }

    let oldMode = activeMode
    activeMode = targetMode
    if oldMode != targetMode && !config.onModeChanged.isEmpty {
        guard let token: RunSessionGuard = .isServerEnabled else { return }
        try await runLightSession(.onModeChanged, token) {
            _ = try await config.onModeChanged.runCmdSeq(.defaultEnv, .emptyStdin)
        }
    }
}

struct HotkeyBinding: Equatable, Sendable {
    let modifiers: NSEvent.ModifierFlags
    let keyCode: Key
    let commands: [any Command]
    let descriptionWithKeyCode: String
    let descriptionWithKeyNotation: String

    init(_ modifiers: NSEvent.ModifierFlags, _ keyCode: Key, _ commands: [any Command], descriptionWithKeyNotation: String) {
        self.modifiers = modifiers
        self.keyCode = keyCode
        self.commands = commands
        self.descriptionWithKeyCode = modifiers.isEmpty
            ? keyCode.toString()
            : modifiers.toString() + "-" + keyCode.toString()
        self.descriptionWithKeyNotation = descriptionWithKeyNotation
    }

    static func == (lhs: HotkeyBinding, rhs: HotkeyBinding) -> Bool {
        lhs.modifiers == rhs.modifiers &&
            lhs.keyCode == rhs.keyCode &&
            lhs.descriptionWithKeyCode == rhs.descriptionWithKeyCode &&
            zip(lhs.commands, rhs.commands).allSatisfy { $0.equals($1) }
    }
}

func parseBindings(_ raw: TOMLValueConvertible, _ backtrace: TomlBacktrace, _ errors: inout [TomlParseError], _ mapping: [String: Key], _ mod: String) -> [String: HotkeyBinding] {
    guard let rawTable = raw.table else {
        errors += [expectedActualTypeError(expected: .table, actual: raw.type, backtrace)]
        return [:]
    }
    var result: [String: HotkeyBinding] = [:]
    for (binding, rawCommand): (String, TOMLValueConvertible) in rawTable {
        let backtrace = backtrace + .key(binding)
        let binding = parseBinding(binding, backtrace, mapping, mod)
            .flatMap { modifiers, key -> ParsedToml<HotkeyBinding> in
                parseCommandOrCommands(rawCommand).toParsedToml(backtrace).map {
                    HotkeyBinding(modifiers, key, $0, descriptionWithKeyNotation: binding)
                }
            }
            .getOrNil(appendErrorTo: &errors)
        if let binding {
            if result.keys.contains(binding.descriptionWithKeyCode) {
                errors.append(.semantic(backtrace, "'\(binding.descriptionWithKeyCode)' Binding redeclaration"))
            }
            result[binding.descriptionWithKeyCode] = binding
        }
    }
    return result
}

func parseBinding(_ raw: String, _ backtrace: TomlBacktrace, _ mapping: [String: Key], _ mod: String) -> ParsedToml<(NSEvent.ModifierFlags, Key)> {
    let effectiveRaw = mod.isEmpty ? raw : raw.replacingOccurrences(of: "mod-", with: mod + "-")
    let rawKeys = effectiveRaw.split(separator: "-")
    let modifiers: ParsedToml<NSEvent.ModifierFlags> = rawKeys.dropLast()
        .mapAllOrFailure {
            modifiersMap[String($0)].orFailure(.semantic(backtrace, "Can't parse modifiers in '\(effectiveRaw)' binding"))
        }
        .map { NSEvent.ModifierFlags($0) }
    let key: ParsedToml<Key> = rawKeys.last.flatMap { mapping[String($0)] }
        .orFailure(.semantic(backtrace, "Can't parse the key in '\(effectiveRaw)' binding"))
    return modifiers.flatMap { modifiers -> ParsedToml<(NSEvent.ModifierFlags, Key)> in
        key.flatMap { key -> ParsedToml<(NSEvent.ModifierFlags, Key)> in
            .success((modifiers, key))
        }
    }
}

// MARK: - CGEventTap Handling

@MainActor
func handleEventOnMainThread(type: CGEventType, keyCode: Int, modifiers: NSEvent.ModifierFlags, isRepeat: Bool) -> Bool {
    guard let bindings = activeBindings[UInt32(keyCode)] else { return false }
    let match = bindings.first { binding in
        modifiers.contains(binding.modifiers)
    }

    if type == .keyDown {
        if let binding = match {
            let description = binding.descriptionWithKeyCode

            if isRepeat {
                // If it's a repeat, we swallow it if we are handling it manually.
                return true
            }

            repeatingTasks[UInt32(keyCode)]?.cancel()
            repeatingTasks[UInt32(keyCode)] = Task {
                if let activeMode {
                    try? await runLightSession(.hotkeyBinding, .checkServerIsEnabledOrDie) { () throws in
                        _ = try await config.modes[activeMode]?.bindings[description]?.commands
                            .runCmdSeq(.defaultEnv, .emptyStdin)
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000) // Initial delay
                    if Task.isCancelled { return }

                    while !Task.isCancelled {
                        try? await runLightSession(.hotkeyBinding, .checkServerIsEnabledOrDie) { () throws in
                            _ = try await config.modes[activeMode]?.bindings[description]?.commands
                                .runCmdSeq(.defaultEnv, .emptyStdin)
                        }
                        try? await Task.sleep(nanoseconds: 100_000_000) // Repeat interval
                    }
                }
            }
            return true // Swallow event
        }
    } else if type == .keyUp {
        let task = repeatingTasks.removeValue(forKey: UInt32(keyCode))
        task?.cancel()
        if task != nil || match != nil {
            return true // Swallow event
        }
    }

    return false
}
