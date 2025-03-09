// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import Shaft
import SwiftSDL3

/// Translate SDL scancode to Shaft scancode
func mapSDLScancode(_ scancode: SDL_Scancode) -> PhysicalKeyboardKey? {
    return switch scancode {
    case SDL_SCANCODE_A: .keyA
    case SDL_SCANCODE_B: .keyB
    case SDL_SCANCODE_C: .keyC
    case SDL_SCANCODE_D: .keyD
    case SDL_SCANCODE_E: .keyE
    case SDL_SCANCODE_F: .keyF
    case SDL_SCANCODE_G: .keyG
    case SDL_SCANCODE_H: .keyH
    case SDL_SCANCODE_I: .keyI
    case SDL_SCANCODE_J: .keyJ
    case SDL_SCANCODE_K: .keyK
    case SDL_SCANCODE_L: .keyL
    case SDL_SCANCODE_M: .keyM
    case SDL_SCANCODE_N: .keyN
    case SDL_SCANCODE_O: .keyO
    case SDL_SCANCODE_P: .keyP
    case SDL_SCANCODE_Q: .keyQ
    case SDL_SCANCODE_R: .keyR
    case SDL_SCANCODE_S: .keyS
    case SDL_SCANCODE_T: .keyT
    case SDL_SCANCODE_U: .keyU
    case SDL_SCANCODE_V: .keyV
    case SDL_SCANCODE_W: .keyW
    case SDL_SCANCODE_X: .keyX
    case SDL_SCANCODE_Y: .keyY
    case SDL_SCANCODE_Z: .keyZ
    case SDL_SCANCODE_1: .digit1
    case SDL_SCANCODE_2: .digit2
    case SDL_SCANCODE_3: .digit3
    case SDL_SCANCODE_4: .digit4
    case SDL_SCANCODE_5: .digit5
    case SDL_SCANCODE_6: .digit6
    case SDL_SCANCODE_7: .digit7
    case SDL_SCANCODE_8: .digit8
    case SDL_SCANCODE_9: .digit9
    case SDL_SCANCODE_0: .digit0
    // case SDL_SCANCODE_RETURN: .return
    case SDL_SCANCODE_ESCAPE: .escape
    case SDL_SCANCODE_BACKSPACE: .backspace
    case SDL_SCANCODE_TAB: .tab
    case SDL_SCANCODE_SPACE: .space
    case SDL_SCANCODE_MINUS: .minus
    case SDL_SCANCODE_EQUALS: .equal
    case SDL_SCANCODE_LEFTBRACKET: .bracketLeft
    case SDL_SCANCODE_RIGHTBRACKET: .bracketRight
    case SDL_SCANCODE_BACKSLASH: .backslash
    // case SDL_SCANCODE_NONUSHASH: .nonushash
    case SDL_SCANCODE_SEMICOLON: .semicolon
    // case SDL_SCANCODE_APOSTROPHE: .apostrophe
    // case SDL_SCANCODE_GRAVE: .grave
    case SDL_SCANCODE_COMMA: .comma
    case SDL_SCANCODE_PERIOD: .period
    case SDL_SCANCODE_SLASH: .slash
    case SDL_SCANCODE_CAPSLOCK: .capsLock
    case SDL_SCANCODE_F1: .f1
    case SDL_SCANCODE_F2: .f2
    case SDL_SCANCODE_F3: .f3
    case SDL_SCANCODE_F4: .f4
    case SDL_SCANCODE_F5: .f5
    case SDL_SCANCODE_F6: .f6
    case SDL_SCANCODE_F7: .f7
    case SDL_SCANCODE_F8: .f8
    case SDL_SCANCODE_F9: .f9
    case SDL_SCANCODE_F10: .f10
    case SDL_SCANCODE_F11: .f11
    case SDL_SCANCODE_F12: .f12
    case SDL_SCANCODE_PRINTSCREEN: .printScreen
    case SDL_SCANCODE_SCROLLLOCK: .scrollLock
    case SDL_SCANCODE_PAUSE: .pause
    case SDL_SCANCODE_INSERT: .insert
    case SDL_SCANCODE_HOME: .home
    case SDL_SCANCODE_PAGEUP: .pageUp
    case SDL_SCANCODE_DELETE: .delete
    case SDL_SCANCODE_END: .end
    case SDL_SCANCODE_PAGEDOWN: .pageDown
    case SDL_SCANCODE_RIGHT: .arrowRight
    case SDL_SCANCODE_LEFT: .arrowLeft
    case SDL_SCANCODE_DOWN: .arrowDown
    case SDL_SCANCODE_UP: .arrowUp
    // case SDL_SCANCODE_NUMLOCKCLEAR: .numlockClear
    // case SDL_SCANCODE_KP_DIVIDE: .kp_divide
    // case SDL_SCANCODE_KP_MULTIPLY: .kp_multiply
    // case SDL_SCANCODE_KP_MINUS: .kp_minus
    // case SDL_SCANCODE_KP_PLUS: .kp_plus
    // case SDL_SCANCODE_KP_ENTER: .kp_enter
    // case SDL_SCANCODE_KP_1: .kp_1
    // case SDL_SCANCODE_KP_2: .kp_2
    // case SDL_SCANCODE_KP_3: .kp_3
    // case SDL_SCANCODE_KP_4: .kp_4
    // case SDL_SCANCODE_KP_5: .kp_5
    // case SDL_SCANCODE_KP_6: .kp_6
    // case SDL_SCANCODE_KP_7: .kp_7
    // case SDL_SCANCODE_KP_8: .kp_8
    // case SDL_SCANCODE_KP_9: .kp_9
    // case SDL_SCANCODE_KP_0: .kp_0
    // case SDL_SCANCODE_KP_PERIOD: .kp_period
    // case SDL_SCANCODE_NONUSBACKSLASH: .nonusbackslash
    // case SDL_SCANCODE_APPLICATION: .application
    case SDL_SCANCODE_POWER: .power
    // case SDL_SCANCODE_KP_EQUALS: .kp_equals
    case SDL_SCANCODE_F13: .f13
    case SDL_SCANCODE_F14: .f14
    case SDL_SCANCODE_F15: .f15
    case SDL_SCANCODE_F16: .f16
    case SDL_SCANCODE_F17: .f17
    case SDL_SCANCODE_F18: .f18
    case SDL_SCANCODE_F19: .f19
    case SDL_SCANCODE_F20: .f20
    case SDL_SCANCODE_F21: .f21
    case SDL_SCANCODE_F22: .f22
    case SDL_SCANCODE_F23: .f23
    case SDL_SCANCODE_F24: .f24
    // case SDL_SCANCODE_EXECUTE: .execute
    case SDL_SCANCODE_HELP: .help
    case SDL_SCANCODE_MENU: .contextMenu
    case SDL_SCANCODE_SELECT: .select
    // case SDL_SCANCODE_STOP: .stop
    case SDL_SCANCODE_AGAIN: .again
    case SDL_SCANCODE_UNDO: .undo
    case SDL_SCANCODE_CUT: .cut
    case SDL_SCANCODE_COPY: .copy
    case SDL_SCANCODE_PASTE: .paste
    case SDL_SCANCODE_FIND: .find
    case SDL_SCANCODE_MUTE: .audioVolumeMute
    case SDL_SCANCODE_VOLUMEUP: .audioVolumeUp
    case SDL_SCANCODE_VOLUMEDOWN: .audioVolumeDown
    // case SDL_SCANCODE_KP_COMMA: .kp_comma
    // case SDL_SCANCODE_KP_EQUALSAS400: .kp_equalsas400
    // case SDL_SCANCODE_INTERNATIONAL1: .international1
    // case SDL_SCANCODE_INTERNATIONAL2: .international2
    // case SDL_SCANCODE_INTERNATIONAL3: .international3
    // case SDL_SCANCODE_INTERNATIONAL4: .international4
    // case SDL_SCANCODE_INTERNATIONAL5: .international5
    // case SDL_SCANCODE_INTERNATIONAL6: .international6
    // case SDL_SCANCODE_INTERNATIONAL7: .international7
    // case SDL_SCANCODE_INTERNATIONAL8: .international8
    // case SDL_SCANCODE_INTERNATIONAL9: .international9
    case SDL_SCANCODE_LANG1: .lang1
    case SDL_SCANCODE_LANG2: .lang2
    case SDL_SCANCODE_LANG3: .lang3
    case SDL_SCANCODE_LANG4: .lang4
    case SDL_SCANCODE_LANG5: .lang5
    // case SDL_SCANCODE_LANG6: .lang6
    // case SDL_SCANCODE_LANG7: .lang7
    // case SDL_SCANCODE_LANG8: .lang8
    // case SDL_SCANCODE_LANG9: .lang9
    // case SDL_SCANCODE_ALTERASE: .alterase
    // case SDL_SCANCODE_SYSREQ: .sysreq
    // case SDL_SCANCODE_CANCEL: .cancel
    // case SDL_SCANCODE_CLEAR: .clear
    // case SDL_SCANCODE_PRIOR: .prior
    // case SDL_SCANCODE_RETURN2: .return2
    // case SDL_SCANCODE_SEPARATOR: .separator
    // case SDL_SCANCODE_OUT: .out
    // case SDL_SCANCODE_OPER: .oper
    // case SDL_SCANCODE_CLEARAGAIN: .clearagain
    // case SDL_SCANCODE_CRSEL: .crsel
    // case SDL_SCANCODE_EXSEL: .exsel
    // case SDL_SCANCODE_KP_00: .kp_00
    // case SDL_SCANCODE_KP_000: .kp_000
    // case SDL_SCANCODE_THOUSANDSSEPARATOR: .thousandsseparator
    // case SDL_SCANCODE_DECIMALSEPARATOR: .decimalseparator
    // case SDL_SCANCODE_CURRENCYUNIT: .currencyunit
    // case SDL_SCANCODE_CURRENCYSUBUNIT: .currencysubunit
    // case SDL_SCANCODE_KP_LEFTPAREN: .kp_leftparen
    // case SDL_SCANCODE_KP_RIGHTPAREN: .kp_rightparen
    // case SDL_SCANCODE_KP_LEFTBRACE: .kp_leftbrace
    // case SDL_SCANCODE_KP_RIGHTBRACE: .kp_rightbrace
    // case SDL_SCANCODE_KP_TAB: .kp_tab
    // case SDL_SCANCODE_KP_BACKSPACE: .kp_backspace
    // case SDL_SCANCODE_KP_A: .kp_a
    // case SDL_SCANCODE_KP_B: .kp_b
    // case SDL_SCANCODE_KP_C: .kp_c
    // case SDL_SCANCODE_KP_D: .kp_d
    // case SDL_SCANCODE_KP_E: .kp_e
    // case SDL_SCANCODE_KP_F: .kp_f
    // case SDL_SCANCODE_KP_XOR: .kp_xor
    // case SDL_SCANCODE_KP_POWER: .kp_power
    // case SDL_SCANCODE_KP_PERCENT: .kp_percent
    // case SDL_SCANCODE_KP_LESS: .kp_less
    // case SDL_SCANCODE_KP_GREATER: .kp_greater
    // case SDL_SCANCODE_KP_AMPERSAND: .kp_ampersand
    // case SDL_SCANCODE_KP_DBLAMPERSAND: .kp_dblampersand
    // case SDL_SCANCODE_KP_VERTICALBAR: .kp_verticalbar
    // case SDL_SCANCODE_KP_DBLVERTICALBAR: .kp_dblverticalbar
    // case SDL_SCANCODE_KP_COLON: .kp_colon
    // case SDL_SCANCODE_KP_HASH: .kp_hash
    // case SDL_SCANCODE_KP_SPACE: .kp_space
    // case SDL_SCANCODE_KP_AT: .kp_at
    // case SDL_SCANCODE_KP_EXCLAM: .kp_exclam
    // case SDL_SCANCODE_KP_MEMSTORE: .kp_memstore
    // case SDL_SCANCODE_KP_MEMRECALL: .kp_memrecall
    // case SDL_SCANCODE_KP_MEMCLEAR: .kp_memclear
    // case SDL_SCANCODE_KP_MEMADD: .kp_memadd
    // case SDL_SCANCODE_KP_MEMSUBTRACT: .kp_memsubtract
    // case SDL_SCANCODE_KP_MEMMULTIPLY: .kp_memmultiply
    // case SDL_SCANCODE_KP_MEMDIVIDE: .kp_memdivide
    // case SDL_SCANCODE_KP_PLUSMINUS: .kp_plusminus
    // case SDL_SCANCODE_KP_CLEAR: .kp_clear
    // case SDL_SCANCODE_KP_CLEARENTRY: .kp_clearentry
    // case SDL_SCANCODE_KP_BINARY: .kp_binary
    // case SDL_SCANCODE_KP_OCTAL: .kp_octal
    // case SDL_SCANCODE_KP_DECIMAL: .kp_decimal
    // case SDL_SCANCODE_KP_HEXADECIMAL: .kp_hexadecimal
    case SDL_SCANCODE_LCTRL: .controlLeft
    case SDL_SCANCODE_LSHIFT: .shiftLeft
    case SDL_SCANCODE_LALT: .altLeft
    case SDL_SCANCODE_LGUI: .metaLeft
    case SDL_SCANCODE_RCTRL: .controlRight
    case SDL_SCANCODE_RSHIFT: .shiftRight
    case SDL_SCANCODE_RALT: .altRight
    case SDL_SCANCODE_RGUI: .metaRight
    // case SDL_SCANCODE_MODE: .mode
    case SDL_SCANCODE_MEDIA_NEXT_TRACK: .mediaTrackNext
    case SDL_SCANCODE_MEDIA_PREVIOUS_TRACK: .mediaTrackPrevious
    case SDL_SCANCODE_MEDIA_STOP: .mediaStop
    case SDL_SCANCODE_MEDIA_PLAY: .mediaPlay
    case SDL_SCANCODE_MUTE: .audioVolumeMute
    case SDL_SCANCODE_MEDIA_SELECT: .mediaSelect
    // case SDL_SCANCODE_WWW: .www
    // case SDL_SCANCODE_CALCULATOR: .launchCalculator
    // case SDL_SCANCODE_COMPUTER: .computer
    // case SDL_SCANCODE_AC_SEARCH: .ac_search
    // case SDL_SCANCODE_AC_HOME: .ac_home
    // case SDL_SCANCODE_AC_BACK: .ac_back
    // case SDL_SCANCODE_AC_FORWARD: .ac_forward
    // case SDL_SCANCODE_AC_STOP: .ac_stop
    // case SDL_SCANCODE_AC_REFRESH: .ac_refresh
    // case SDL_SCANCODE_AC_BOOKMARKS: .ac_bookmarks
    // case SDL_SCANCODE_BRIGHTNESS_DOWN: .brightnessDown
    // case SDL_SCANCODE_BRIGHTNESSUP: .brightnessUp
    // case SDL_SCANCODE_DISPLAYSWITCH: .displaySwap
    // case SDL_SCANCODE_KBDILLUMTOGGLE: .kbdIlluminateToggle
    // case SDL_SCANCODE_KBDILLUM_DOWN: .kbdIllumDown
    // case SDL_SCANCODE_KBDILLUM_UP: .kbdIllumUp
    case SDL_SCANCODE_MEDIA_EJECT: .eject
    case SDL_SCANCODE_SLEEP: .sleep
    case SDL_SCANCODE_APPLICATION: .launchApp1
    // case SDL_SCANCODE_APP2: .launchApp2
    case SDL_SCANCODE_MEDIA_REWIND: .mediaRewind
    case SDL_SCANCODE_MEDIA_FAST_FORWARD: .mediaFastForward
    // case SDL_SCANCODE_SOFTLEFT: .softleft
    // case SDL_SCANCODE_SOFTRIGHT: .softright
    // case SDL_SCANCODE_CALL: .call
    // case SDL_SCANCODE_ENDCALL: .endcall
    default: nil
    }
}

/// Translate SDL_KeyCode to Shaft logical key
func mapSDLKeycode(_ keycode: SDL_Keycode) -> LogicalKeyboardKey? {

    return switch keycode {
    // SDLK_RETURN: .return
    case SDLK_ESCAPE: .escape
    case SDLK_BACKSPACE: .backspace
    case SDLK_TAB: .tab
    case SDLK_SPACE: .space
    case SDLK_EXCLAIM: .exclamation
    // case SDLK_QUOTEDBL: .quote
    case SDLK_HASH: .numberSign
    case SDLK_PERCENT: .percent
    case SDLK_DOLLAR: .dollar
    case SDLK_AMPERSAND: .ampersand
    // case SDLK_QUOTE: .quote
    case SDLK_LEFTPAREN: .parenthesisLeft
    case SDLK_RIGHTPAREN: .parenthesisRight
    case SDLK_ASTERISK: .asterisk
    case SDLK_PLUS: .add
    case SDLK_COMMA: .comma
    case SDLK_MINUS: .minus
    case SDLK_PERIOD: .period
    case SDLK_SLASH: .slash
    case SDLK_0: .digit0
    case SDLK_1: .digit1
    case SDLK_2: .digit2
    case SDLK_3: .digit3
    case SDLK_4: .digit4
    case SDLK_5: .digit5
    case SDLK_6: .digit6
    case SDLK_7: .digit7
    case SDLK_8: .digit8
    case SDLK_9: .digit9
    case SDLK_COLON: .colon
    case SDLK_SEMICOLON: .semicolon
    case SDLK_LESS: .less
    case SDLK_EQUALS: .equal
    case SDLK_GREATER: .greater
    case SDLK_QUESTION: .question
    case SDLK_AT: .at
    case SDLK_LEFTBRACKET: .bracketLeft
    case SDLK_BACKSLASH: .backslash
    case SDLK_RIGHTBRACKET: .bracketRight
    case SDLK_CARET: .caret
    case SDLK_UNDERSCORE: .underscore
    // case SDLK_BACKQUOTE: .backquote
    case SDLK_A: .keyA
    case SDLK_B: .keyB
    case SDLK_C: .keyC
    case SDLK_D: .keyD
    case SDLK_E: .keyE
    case SDLK_F: .keyF
    case SDLK_G: .keyG
    case SDLK_H: .keyH
    case SDLK_I: .keyI
    case SDLK_J: .keyJ
    case SDLK_K: .keyK
    case SDLK_L: .keyL
    case SDLK_M: .keyM
    case SDLK_N: .keyN
    case SDLK_O: .keyO
    case SDLK_P: .keyP
    case SDLK_Q: .keyQ
    case SDLK_R: .keyR
    case SDLK_S: .keyS
    case SDLK_T: .keyT
    case SDLK_U: .keyU
    case SDLK_V: .keyV
    case SDLK_W: .keyW
    case SDLK_X: .keyX
    case SDLK_Y: .keyY
    case SDLK_Z: .keyZ
    case SDLK_CAPSLOCK: .capsLock
    case SDLK_F1: .f1
    case SDLK_F2: .f2
    case SDLK_F3: .f3
    case SDLK_F4: .f4
    case SDLK_F5: .f5
    case SDLK_F6: .f6
    case SDLK_F7: .f7
    case SDLK_F8: .f8
    case SDLK_F9: .f9
    case SDLK_F10: .f10
    case SDLK_F11: .f11
    case SDLK_F12: .f12
    case SDLK_PRINTSCREEN: .printScreen
    case SDLK_SCROLLLOCK: .scrollLock
    case SDLK_PAUSE: .pause
    case SDLK_INSERT: .insert
    case SDLK_HOME: .home
    case SDLK_PAGEUP: .pageUp
    case SDLK_DELETE: .delete
    case SDLK_END: .end
    case SDLK_PAGEDOWN: .pageDown
    case SDLK_RIGHT: .arrowRight
    case SDLK_LEFT: .arrowLeft
    case SDLK_DOWN: .arrowDown
    case SDLK_UP: .arrowUp
    case SDLK_NUMLOCKCLEAR: .numLock
    case SDLK_KP_DIVIDE: .numpadDivide
    case SDLK_KP_MULTIPLY: .numpadMultiply
    case SDLK_KP_MINUS: .numpadSubtract
    case SDLK_KP_PLUS: .numpadAdd
    case SDLK_KP_ENTER: .numpadEnter
    case SDLK_KP_1: .numpad1
    case SDLK_KP_2: .numpad2
    case SDLK_KP_3: .numpad3
    case SDLK_KP_4: .numpad4
    case SDLK_KP_5: .numpad5
    case SDLK_KP_6: .numpad6
    case SDLK_KP_7: .numpad7
    case SDLK_KP_8: .numpad8
    case SDLK_KP_9: .numpad9
    case SDLK_KP_0: .numpad0
    // case SDLK_KP_PERIOD: .numpadPeriod
    case SDLK_APPLICATION: .launchApplication1
    case SDLK_POWER: .power
    case SDLK_KP_EQUALS: .numpadEqual
    case SDLK_F13: .f13
    case SDLK_F14: .f14
    case SDLK_F15: .f15
    case SDLK_F16: .f16
    case SDLK_F17: .f17
    case SDLK_F18: .f18
    case SDLK_F19: .f19
    case SDLK_F20: .f20
    case SDLK_F21: .f21
    case SDLK_F22: .f22
    case SDLK_F23: .f23
    case SDLK_F24: .f24
    case SDLK_EXECUTE: .execute
    case SDLK_HELP: .help
    case SDLK_MENU: .contextMenu
    case SDLK_SELECT: .select
    case SDLK_STOP: .mediaStop
    case SDLK_AGAIN: .again
    case SDLK_UNDO: .undo
    case SDLK_CUT: .cut
    case SDLK_COPY: .copy
    case SDLK_PASTE: .paste
    case SDLK_FIND: .find
    case SDLK_MUTE: .audioVolumeMute
    // case SDLK_VOLUMEUP: .volumeUp
    // case SDLK_VOLUMEDOWN: .volumeDown
    case SDLK_KP_COMMA: .numpadComma
    // case SDLK_KP_EQUALSAS400: .keypadEqualsAS400
    // case SDLK_ALTERASE: .altErase
    // case SDLK_SYSREQ: .sysReq
    // case SDLK_CANCEL: .cancel
    // case SDLK_CLEAR: .clear
    // case SDLK_PRIOR: .prior
    // case SDLK_RETURN2: .return2
    // case SDLK_SEPARATOR: .separator
    // case SDLK_OUT: .out
    // case SDLK_OPER: .oper
    // case SDLK_CLEARAGAIN: .clearAgain
    // case SDLK_CRSEL: .crSel
    // case SDLK_EXSEL: .exSel
    // case SDLK_KP_00: .keypad00
    // case SDLK_KP_000: .keypad000
    // case SDLK_THOUSANDSSEPARATOR: .thousandsSeparator
    // case SDLK_DECIMALSEPARATOR: .decimalSeparator
    // case SDLK_CURRENCYUNIT: .currencyUnit
    // case SDLK_CURRENCYSUBUNIT: .currencySubUnit
    // case SDLK_KP_LEFTPAREN: .keypadLeftParenthesis
    // case SDLK_KP_RIGHTPAREN: .keypadRightParenthesis
    // case SDLK_KP_LEFTBRACE: .keypadLeftBrace
    // case SDLK_KP_RIGHTBRACE: .keypadRightBrace
    // case SDLK_KP_TAB: .keypadTab
    // case SDLK_KP_BACKSPACE: .keypadBackspace
    // case SDLK_KP_A: .keypadA
    // case SDLK_KP_B: .keypadB
    // case SDLK_KP_C: .keypadC
    // case SDLK_KP_D: .keypadD
    // case SDLK_KP_E: .keypadE
    // case SDLK_KP_F: .keypadF
    // case SDLK_KP_XOR: .keypadXor
    // case SDLK_KP_POWER: .keypadPower
    // case SDLK_KP_PERCENT: .keypadPercent
    // case SDLK_KP_LESS: .keypadLessThan
    // case SDLK_KP_GREATER: .keypadGreaterThan
    // case SDLK_KP_AMPERSAND: .keypadAmpersand
    // case SDLK_KP_DBLAMPERSAND: .keypadDoubleAmpersand
    // case SDLK_KP_VERTICALBAR: .keypadVerticalBar
    // case SDLK_KP_DBLVERTICALBAR: .keypadDoubleVerticalBar
    // case SDLK_KP_COLON: .keypadColon
    // case SDLK_KP_HASH: .keypadHash
    // case SDLK_KP_SPACE: .keypadSpace
    // case SDLK_KP_AT: .keypadAt
    // case SDLK_KP_EXCLAM: .keypadExclamation
    // case SDLK_KP_MEMSTORE: .keypadMemStore
    // case SDLK_KP_MEMRECALL: .keypadMemRecall
    // case SDLK_KP_MEMCLEAR: .keypadMemClear
    // case SDLK_KP_MEMADD: .keypadMemAdd
    // case SDLK_KP_MEMSUBTRACT: .keypadMemSubtract
    // case SDLK_KP_MEMMULTIPLY: .keypadMemMultiply
    // case SDLK_KP_MEMDIVIDE: .keypadMemDivide
    // case SDLK_KP_PLUSMINUS: .keypadPlusMinus
    // case SDLK_KP_CLEAR: .keypadClear
    // case SDLK_KP_CLEARENTRY: .keypadClearEntry
    // case SDLK_KP_BINARY: .keypadBinary
    // case SDLK_KP_OCTAL: .keypadOctal
    // case SDLK_KP_DECIMAL: .keypadDecimal
    // case SDLK_KP_HEXADECIMAL: .keypadHexadecimal
    case SDLK_LCTRL: .controlLeft
    case SDLK_LSHIFT: .shiftLeft
    case SDLK_LALT: .altLeft
    case SDLK_LGUI: .metaLeft
    case SDLK_RCTRL: .controlRight
    case SDLK_RSHIFT: .shiftRight
    case SDLK_RALT: .altRight
    case SDLK_RGUI: .metaRight
    // case SDLK_MODE: .mode
    case SDLK_MEDIA_NEXT_TRACK: .mediaTrackNext
    case SDLK_MEDIA_PREVIOUS_TRACK: .mediaTrackPrevious
    case SDLK_MEDIA_STOP: .mediaStop
    case SDLK_MEDIA_PLAY: .mediaPlay
    case SDLK_MUTE: .audioVolumeMute
    // case SDLK_MEDIASELECT: .mediaSelect
    // case SDLK_WWW: .www
    // case SDLK_MAIL: .mail
    // case SDLK_CALCULATOR: .calculator
    // case SDLK_COMPUTER: .computer
    // case SDLK_AC_SEARCH: .acSearch
    // case SDLK_AC_HOME: .acHome
    // case SDLK_AC_BACK: .acBack
    // case SDLK_AC_FORWARD: .acForward
    // case SDLK_AC_STOP: .acStop
    // case SDLK_AC_REFRESH: .acRefresh
    // case SDLK_AC_BOOKMARKS: .acBookmarks
    // case SDLK_BRIGHTNESSDOWN: .brightnessDown
    // case SDLK_BRIGHTNESSUP: .brightnessUp
    // case SDLK_DISPLAYSWITCH: .displaySwitch
    // case SDLK_KBDILLUMTOGGLE: .kbdIllumToggle
    // case SDLK_KBDILLUMDOWN: .kbdIllumDown
    // case SDLK_KBDILLUMUP: .kbdIllumUp
    // case SDLK_EJECT: .eject
    // case SDLK_SLEEP: .sleep
    // case SDLK_APP1: .launchApplication1
    // case SDLK_APP2: .launchApplication2
    // case SDLK_AUDIOREWIND: .audioRewind
    // case SDLK_AUDIOFASTFORWARD: .audioFastForward
    // case SDLK_SOFTLEFT: .softLeft
    // case SDLK_SOFTRIGHT: .softRight
    // case SDLK_CALL: .call
    // case SDLK_ENDCALL: .endCall
    default: nil
    }
}
