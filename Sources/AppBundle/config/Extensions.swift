import AppKit
import HotKey

extension NSEvent.ModifierFlags {
    public func toString() -> String {
        var result: [String] = []
        if contains(.lOption) { result.append("lalt") }
        else if contains(.rOption) { result.append("ralt") }
        else if contains(.option) { result.append("alt") }

        if contains(.lControl) { result.append("lctrl") }
        else if contains(.rControl) { result.append("rctrl") }
        else if contains(.control) { result.append("ctrl") }

        if contains(.lCommand) { result.append("lcmd") }
        else if contains(.rCommand) { result.append("rcmd") }
        else if contains(.command) { result.append("cmd") }

        if contains(.lShift) { result.append("lshift") }
        else if contains(.rShift) { result.append("rshift") }
        else if contains(.shift) { result.append("shift") }

        return result.joined(separator: "-")
    }

    public static let lOption = NSEvent.ModifierFlags(rawValue: 0x20)
    public static let rOption = NSEvent.ModifierFlags(rawValue: 0x40)
    public static let lShift = NSEvent.ModifierFlags(rawValue: 0x02)
    public static let rShift = NSEvent.ModifierFlags(rawValue: 0x04)
    public static let lCommand = NSEvent.ModifierFlags(rawValue: 0x08)
    public static let rCommand = NSEvent.ModifierFlags(rawValue: 0x10)
    public static let lControl = NSEvent.ModifierFlags(rawValue: 0x01)
    public static let rControl = NSEvent.ModifierFlags(rawValue: 0x2000)

    public func toCGEventFlags() -> CGEventFlags {
        var flags: CGEventFlags = []
        if contains(.capsLock) { flags.insert(.maskAlphaShift) }
        if contains(.shift) { flags.insert(.maskShift) }
        if contains(.control) { flags.insert(.maskControl) }
        if contains(.option) { flags.insert(.maskAlternate) }
        if contains(.command) { flags.insert(.maskCommand) }
        if contains(.help) { flags.insert(.maskHelp) }
        if contains(.numericPad) { flags.insert(.maskNumericPad) }
        return flags
    }
}

extension Key {
    public func toString() -> String {
        switch self {
            case .a: "a"
            case .b: "b"
            case .c: "c"
            case .d: "d"
            case .e: "e"
            case .f: "f"
            case .g: "g"
            case .h: "h"
            case .i: "i"
            case .j: "j"
            case .k: "k"
            case .l: "l"
            case .m: "m"
            case .n: "n"
            case .o: "o"
            case .p: "p"
            case .q: "q"
            case .r: "r"
            case .s: "s"
            case .t: "t"
            case .u: "u"
            case .v: "v"
            case .w: "w"
            case .x: "x"
            case .y: "y"
            case .z: "z"

            case .zero: "0"
            case .one: "1"
            case .two: "2"
            case .three: "3"
            case .four: "4"
            case .five: "5"
            case .six: "6"
            case .seven: "7"
            case .eight: "8"
            case .nine: "9"

            case .period: "period"
            case .quote: "quote"
            case .leftBracket: "leftSquareBracket"
            case .rightBracket: "rightSquareBracket"
            case .semicolon: "semicolon"
            case .slash: "slash"
            case .backslash: "backslash"
            case .comma: "comma"
            case .equal: "equal"
            case .grave: "backtick"
            case .minus: "minus"
            case .space: "space"
            case .tab: "tab"
            case .return: "enter"
            case .pageUp: "pageUp"
            case .pageDown: "pageDown"
            case .home: "home"
            case .end: "end"
            case .leftArrow: "left"
            case .downArrow: "down"
            case .upArrow: "up"
            case .rightArrow: "right"
            case .escape: "esc"
            case .delete: "backspace"
            case .section: "sectionSign"

            case .f1: "f1"
            case .f2: "f2"
            case .f3: "f3"
            case .f4: "f4"
            case .f5: "f5"
            case .f6: "f6"
            case .f7: "f7"
            case .f8: "f8"
            case .f9: "f9"
            case .f10: "f10"
            case .f11: "f11"
            case .f12: "f12"
            case .f13: "f13"
            case .f14: "f14"
            case .f15: "f15"
            case .f16: "f16"
            case .f17: "f17"
            case .f18: "f18"
            case .f19: "f19"
            case .f20: "f20"

            case .keypad0: "keypad0"
            case .keypad1: "keypad1"
            case .keypad2: "keypad2"
            case .keypad3: "keypad3"
            case .keypad4: "keypad4"
            case .keypad5: "keypad5"
            case .keypad6: "keypad6"
            case .keypad7: "keypad7"
            case .keypad8: "keypad8"
            case .keypad9: "keypad9"
            case .keypadClear: "keypadClear"
            case .keypadDecimal: "keypadDecimalMark"
            case .keypadDivide: "keypadDivide"
            case .keypadEnter: "keypadEnter"
            case .keypadEquals: "keypadEqual"
            case .keypadMinus: "keypadMinus"
            case .keypadMultiply: "keypadMultiply"
            case .keypadPlus: "keypadPlus"

            // wtf
            case .command: "cmd"
            case .rightCommand: "rCmd"
            case .option: "alt"
            case .rightOption: "rAlt"
            case .control: "ctrl"
            case .rightControl: "rCtrl"
            case .shift: "shift"
            case .rightShift: "rShift"
            case .function: "function"
            case .capsLock: "capsLock"
            case .forwardDelete: "forwardDelete"
            case .help: "help"
            case .volumeUp: "volumeUp"
            case .volumeDown: "volumeDown"
            case .mute: "mute"
        }
    }
}
