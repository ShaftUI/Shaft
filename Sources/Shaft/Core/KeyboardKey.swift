// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A class with static values that describe the keys that are returned from
/// [RawKeyEvent.physicalKey].
///
/// These represent *physical* keys, which are keys which represent a particular
/// key location on a QWERTY keyboard. It ignores any modifiers, modes, or
/// keyboard layouts which may be in effect. This is contrast to
/// [LogicalKeyboardKey], which represents a logical key interpreted in the
/// context of modifiers, modes, and/or keyboard layouts.
///
/// As an example, if you wanted a game where the key next to the CAPS LOCK (the
/// "A" key on a QWERTY keyboard) moved the player to the left, you'd want to
/// look at the physical key to make sure that regardless of the character the
/// key produces, you got the key that is in that location on the keyboard.
///
/// Conversely, if you wanted to implement an app where the "Q" key "quit"
/// something, you'd want to look at the logical key to detect this, since you
/// would like to have it match the key with "Q" on it, instead of always
/// looking for "the key next to the TAB key", since on a French keyboard,
/// the key next to the TAB key has an "A" on it.
///
/// The values of this enum are based on the USB HID Usage Tables specification.
/// Due to the variations in platform APIs, this may not be the actual HID usage
/// code from the hardware, but a value derived from available information on
/// the platform. See
/// <https://www.usb.org/sites/default/files/documents/hut1_12v2.pdf> for the
/// HID usage values and their meanings.
public enum PhysicalKeyboardKey: UInt, CaseIterable {
    /// Represents the location of the "Hyper" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case hyper = 0x0000_0010

    /// Represents the location of the "Super Key" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case superKey = 0x0000_0011

    /// Represents the location of the "Fn" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case fn = 0x0000_0012

    /// Represents the location of the "Fn Lock" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case fnLock = 0x0000_0013

    /// Represents the location of the "Suspend" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case suspend = 0x0000_0014

    /// Represents the location of the "Resume" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case resume = 0x0000_0015

    /// Represents the location of the "Turbo" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case turbo = 0x0000_0016

    /// Represents the location of the "Privacy Screen Toggle" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case privacyScreenToggle = 0x0000_0017

    /// Represents the location of the "Microphone Mute Toggle" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case microphoneMuteToggle = 0x0000_0018

    /// Represents the location of the "Sleep" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case sleep = 0x0001_0082

    /// Represents the location of the "Wake Up" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case wakeUp = 0x0001_0083

    /// Represents the location of the "Display Toggle Int Ext" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case displayToggleIntExt = 0x0001_00b5

    /// Represents the location of the "Game Button 1" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton1 = 0x0005_ff01

    /// Represents the location of the "Game Button 2" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton2 = 0x0005_ff02

    /// Represents the location of the "Game Button 3" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton3 = 0x0005_ff03

    /// Represents the location of the "Game Button 4" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton4 = 0x0005_ff04

    /// Represents the location of the "Game Button 5" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton5 = 0x0005_ff05

    /// Represents the location of the "Game Button 6" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton6 = 0x0005_ff06

    /// Represents the location of the "Game Button 7" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton7 = 0x0005_ff07

    /// Represents the location of the "Game Button 8" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton8 = 0x0005_ff08

    /// Represents the location of the "Game Button 9" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton9 = 0x0005_ff09

    /// Represents the location of the "Game Button 10" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton10 = 0x0005_ff0a

    /// Represents the location of the "Game Button 11" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton11 = 0x0005_ff0b

    /// Represents the location of the "Game Button 12" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton12 = 0x0005_ff0c

    /// Represents the location of the "Game Button 13" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton13 = 0x0005_ff0d

    /// Represents the location of the "Game Button 14" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton14 = 0x0005_ff0e

    /// Represents the location of the "Game Button 15" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton15 = 0x0005_ff0f

    /// Represents the location of the "Game Button 16" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButton16 = 0x0005_ff10

    /// Represents the location of the "Game Button A" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonA = 0x0005_ff11

    /// Represents the location of the "Game Button B" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonB = 0x0005_ff12

    /// Represents the location of the "Game Button C" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonC = 0x0005_ff13

    /// Represents the location of the "Game Button Left 1" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonLeft1 = 0x0005_ff14

    /// Represents the location of the "Game Button Left 2" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonLeft2 = 0x0005_ff15

    /// Represents the location of the "Game Button Mode" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonMode = 0x0005_ff16

    /// Represents the location of the "Game Button Right 1" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonRight1 = 0x0005_ff17

    /// Represents the location of the "Game Button Right 2" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonRight2 = 0x0005_ff18

    /// Represents the location of the "Game Button Select" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonSelect = 0x0005_ff19

    /// Represents the location of the "Game Button Start" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonStart = 0x0005_ff1a

    /// Represents the location of the "Game Button Thumb Left" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonThumbLeft = 0x0005_ff1b

    /// Represents the location of the "Game Button Thumb Right" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonThumbRight = 0x0005_ff1c

    /// Represents the location of the "Game Button X" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonX = 0x0005_ff1d

    /// Represents the location of the "Game Button Y" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonY = 0x0005_ff1e

    /// Represents the location of the "Game Button Z" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case gameButtonZ = 0x0005_ff1f

    /// Represents the location of the "Usb Reserved" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case usbReserved = 0x0007_0000

    /// Represents the location of the "Usb Error Roll Over" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case usbErrorRollOver = 0x0007_0001

    /// Represents the location of the "Usb Post Fail" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case usbPostFail = 0x0007_0002

    /// Represents the location of the "Usb Error Undefined" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case usbErrorUndefined = 0x0007_0003

    /// Represents the location of the "Key A" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyA = 0x0007_0004

    /// Represents the location of the "Key B" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyB = 0x0007_0005

    /// Represents the location of the "Key C" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyC = 0x0007_0006

    /// Represents the location of the "Key D" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyD = 0x0007_0007

    /// Represents the location of the "Key E" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyE = 0x0007_0008

    /// Represents the location of the "Key F" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyF = 0x0007_0009

    /// Represents the location of the "Key G" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyG = 0x0007_000a

    /// Represents the location of the "Key H" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyH = 0x0007_000b

    /// Represents the location of the "Key I" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyI = 0x0007_000c

    /// Represents the location of the "Key J" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyJ = 0x0007_000d

    /// Represents the location of the "Key K" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyK = 0x0007_000e

    /// Represents the location of the "Key L" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyL = 0x0007_000f

    /// Represents the location of the "Key M" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyM = 0x0007_0010

    /// Represents the location of the "Key N" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyN = 0x0007_0011

    /// Represents the location of the "Key O" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyO = 0x0007_0012

    /// Represents the location of the "Key P" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyP = 0x0007_0013

    /// Represents the location of the "Key Q" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyQ = 0x0007_0014

    /// Represents the location of the "Key R" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyR = 0x0007_0015

    /// Represents the location of the "Key S" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyS = 0x0007_0016

    /// Represents the location of the "Key T" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyT = 0x0007_0017

    /// Represents the location of the "Key U" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyU = 0x0007_0018

    /// Represents the location of the "Key V" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyV = 0x0007_0019

    /// Represents the location of the "Key W" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyW = 0x0007_001a

    /// Represents the location of the "Key X" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyX = 0x0007_001b

    /// Represents the location of the "Key Y" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyY = 0x0007_001c

    /// Represents the location of the "Key Z" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyZ = 0x0007_001d

    /// Represents the location of the "Digit 1" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit1 = 0x0007_001e

    /// Represents the location of the "Digit 2" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit2 = 0x0007_001f

    /// Represents the location of the "Digit 3" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit3 = 0x0007_0020

    /// Represents the location of the "Digit 4" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit4 = 0x0007_0021

    /// Represents the location of the "Digit 5" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit5 = 0x0007_0022

    /// Represents the location of the "Digit 6" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit6 = 0x0007_0023

    /// Represents the location of the "Digit 7" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit7 = 0x0007_0024

    /// Represents the location of the "Digit 8" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit8 = 0x0007_0025

    /// Represents the location of the "Digit 9" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit9 = 0x0007_0026

    /// Represents the location of the "Digit 0" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case digit0 = 0x0007_0027

    /// Represents the location of the "Enter" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case enter = 0x0007_0028

    /// Represents the location of the "Escape" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case escape = 0x0007_0029

    /// Represents the location of the "Backspace" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case backspace = 0x0007_002a

    /// Represents the location of the "Tab" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case tab = 0x0007_002b

    /// Represents the location of the "Space" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case space = 0x0007_002c

    /// Represents the location of the "Minus" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case minus = 0x0007_002d

    /// Represents the location of the "Equal" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case equal = 0x0007_002e

    /// Represents the location of the "Bracket Left" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case bracketLeft = 0x0007_002f

    /// Represents the location of the "Bracket Right" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case bracketRight = 0x0007_0030

    /// Represents the location of the "Backslash" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case backslash = 0x0007_0031

    /// Represents the location of the "Semicolon" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case semicolon = 0x0007_0033

    /// Represents the location of the "Quote" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case quote = 0x0007_0034

    /// Represents the location of the "Backquote" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case backquote = 0x0007_0035

    /// Represents the location of the "Comma" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case comma = 0x0007_0036

    /// Represents the location of the "Period" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case period = 0x0007_0037

    /// Represents the location of the "Slash" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case slash = 0x0007_0038

    /// Represents the location of the "Caps Lock" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case capsLock = 0x0007_0039

    /// Represents the location of the "F1" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f1 = 0x0007_003a

    /// Represents the location of the "F2" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f2 = 0x0007_003b

    /// Represents the location of the "F3" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f3 = 0x0007_003c

    /// Represents the location of the "F4" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f4 = 0x0007_003d

    /// Represents the location of the "F5" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f5 = 0x0007_003e

    /// Represents the location of the "F6" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f6 = 0x0007_003f

    /// Represents the location of the "F7" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f7 = 0x0007_0040

    /// Represents the location of the "F8" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f8 = 0x0007_0041

    /// Represents the location of the "F9" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f9 = 0x0007_0042

    /// Represents the location of the "F10" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f10 = 0x0007_0043

    /// Represents the location of the "F11" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f11 = 0x0007_0044

    /// Represents the location of the "F12" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f12 = 0x0007_0045

    /// Represents the location of the "Print Screen" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case printScreen = 0x0007_0046

    /// Represents the location of the "Scroll Lock" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case scrollLock = 0x0007_0047

    /// Represents the location of the "Pause" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case pause = 0x0007_0048

    /// Represents the location of the "Insert" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case insert = 0x0007_0049

    /// Represents the location of the "Home" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case home = 0x0007_004a

    /// Represents the location of the "Page Up" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case pageUp = 0x0007_004b

    /// Represents the location of the "Delete" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case delete = 0x0007_004c

    /// Represents the location of the "End" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case end = 0x0007_004d

    /// Represents the location of the "Page Down" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case pageDown = 0x0007_004e

    /// Represents the location of the "Arrow Right" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case arrowRight = 0x0007_004f

    /// Represents the location of the "Arrow Left" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case arrowLeft = 0x0007_0050

    /// Represents the location of the "Arrow Down" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case arrowDown = 0x0007_0051

    /// Represents the location of the "Arrow Up" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case arrowUp = 0x0007_0052

    /// Represents the location of the "Num Lock" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numLock = 0x0007_0053

    /// Represents the location of the "Numpad Divide" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadDivide = 0x0007_0054

    /// Represents the location of the "Numpad Multiply" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadMultiply = 0x0007_0055

    /// Represents the location of the "Numpad Subtract" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadSubtract = 0x0007_0056

    /// Represents the location of the "Numpad Add" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadAdd = 0x0007_0057

    /// Represents the location of the "Numpad Enter" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadEnter = 0x0007_0058

    /// Represents the location of the "Numpad 1" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad1 = 0x0007_0059

    /// Represents the location of the "Numpad 2" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad2 = 0x0007_005a

    /// Represents the location of the "Numpad 3" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad3 = 0x0007_005b

    /// Represents the location of the "Numpad 4" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad4 = 0x0007_005c

    /// Represents the location of the "Numpad 5" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad5 = 0x0007_005d

    /// Represents the location of the "Numpad 6" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad6 = 0x0007_005e

    /// Represents the location of the "Numpad 7" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad7 = 0x0007_005f

    /// Represents the location of the "Numpad 8" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad8 = 0x0007_0060

    /// Represents the location of the "Numpad 9" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad9 = 0x0007_0061

    /// Represents the location of the "Numpad 0" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpad0 = 0x0007_0062

    /// Represents the location of the "Numpad Decimal" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadDecimal = 0x0007_0063

    /// Represents the location of the "Intl Backslash" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case intlBackslash = 0x0007_0064

    /// Represents the location of the "Context Menu" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case contextMenu = 0x0007_0065

    /// Represents the location of the "Power" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case power = 0x0007_0066

    /// Represents the location of the "Numpad Equal" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadEqual = 0x0007_0067

    /// Represents the location of the "F13" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f13 = 0x0007_0068

    /// Represents the location of the "F14" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f14 = 0x0007_0069

    /// Represents the location of the "F15" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f15 = 0x0007_006a

    /// Represents the location of the "F16" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f16 = 0x0007_006b

    /// Represents the location of the "F17" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f17 = 0x0007_006c

    /// Represents the location of the "F18" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f18 = 0x0007_006d

    /// Represents the location of the "F19" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f19 = 0x0007_006e

    /// Represents the location of the "F20" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f20 = 0x0007_006f

    /// Represents the location of the "F21" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f21 = 0x0007_0070

    /// Represents the location of the "F22" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f22 = 0x0007_0071

    /// Represents the location of the "F23" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f23 = 0x0007_0072

    /// Represents the location of the "F24" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case f24 = 0x0007_0073

    /// Represents the location of the "Open" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case open = 0x0007_0074

    /// Represents the location of the "Help" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case help = 0x0007_0075

    /// Represents the location of the "Select" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case select = 0x0007_0077

    /// Represents the location of the "Again" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case again = 0x0007_0079

    /// Represents the location of the "Undo" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case undo = 0x0007_007a

    /// Represents the location of the "Cut" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case cut = 0x0007_007b

    /// Represents the location of the "Copy" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case copy = 0x0007_007c

    /// Represents the location of the "Paste" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case paste = 0x0007_007d

    /// Represents the location of the "Find" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case find = 0x0007_007e

    /// Represents the location of the "Audio Volume Mute" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case audioVolumeMute = 0x0007_007f

    /// Represents the location of the "Audio Volume Up" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case audioVolumeUp = 0x0007_0080

    /// Represents the location of the "Audio Volume Down" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case audioVolumeDown = 0x0007_0081

    /// Represents the location of the "Numpad Comma" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadComma = 0x0007_0085

    /// Represents the location of the "Intl Ro" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case intlRo = 0x0007_0087

    /// Represents the location of the "Kana Mode" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case kanaMode = 0x0007_0088

    /// Represents the location of the "Intl Yen" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case intlYen = 0x0007_0089

    /// Represents the location of the "Convert" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case convert = 0x0007_008a

    /// Represents the location of the "Non Convert" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case nonConvert = 0x0007_008b

    /// Represents the location of the "Lang 1" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case lang1 = 0x0007_0090

    /// Represents the location of the "Lang 2" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case lang2 = 0x0007_0091

    /// Represents the location of the "Lang 3" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case lang3 = 0x0007_0092

    /// Represents the location of the "Lang 4" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case lang4 = 0x0007_0093

    /// Represents the location of the "Lang 5" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case lang5 = 0x0007_0094

    /// Represents the location of the "Abort" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case abort = 0x0007_009b

    /// Represents the location of the "Props" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case props = 0x0007_00a3

    /// Represents the location of the "Numpad Paren Left" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadParenLeft = 0x0007_00b6

    /// Represents the location of the "Numpad Paren Right" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadParenRight = 0x0007_00b7

    /// Represents the location of the "Numpad Backspace" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadBackspace = 0x0007_00bb

    /// Represents the location of the "Numpad Memory Store" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadMemoryStore = 0x0007_00d0

    /// Represents the location of the "Numpad Memory Recall" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadMemoryRecall = 0x0007_00d1

    /// Represents the location of the "Numpad Memory Clear" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadMemoryClear = 0x0007_00d2

    /// Represents the location of the "Numpad Memory Add" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadMemoryAdd = 0x0007_00d3

    /// Represents the location of the "Numpad Memory Subtract" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadMemorySubtract = 0x0007_00d4

    /// Represents the location of the "Numpad Sign Change" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadSignChange = 0x0007_00d7

    /// Represents the location of the "Numpad Clear" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadClear = 0x0007_00d8

    /// Represents the location of the "Numpad Clear Entry" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case numpadClearEntry = 0x0007_00d9

    /// Represents the location of the "Control Left" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case controlLeft = 0x0007_00e0

    /// Represents the location of the "Shift Left" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case shiftLeft = 0x0007_00e1

    /// Represents the location of the "Alt Left" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case altLeft = 0x0007_00e2

    /// Represents the location of the "Meta Left" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case metaLeft = 0x0007_00e3

    /// Represents the location of the "Control Right" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case controlRight = 0x0007_00e4

    /// Represents the location of the "Shift Right" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case shiftRight = 0x0007_00e5

    /// Represents the location of the "Alt Right" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case altRight = 0x0007_00e6

    /// Represents the location of the "Meta Right" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case metaRight = 0x0007_00e7

    /// Represents the location of the "Info" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case info = 0x000c_0060

    /// Represents the location of the "Closed Caption Toggle" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case closedCaptionToggle = 0x000c_0061

    /// Represents the location of the "Brightness Up" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case brightnessUp = 0x000c_006f

    /// Represents the location of the "Brightness Down" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case brightnessDown = 0x000c_0070

    /// Represents the location of the "Brightness Toggle" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case brightnessToggle = 0x000c_0072

    /// Represents the location of the "Brightness Minimum" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case brightnessMinimum = 0x000c_0073

    /// Represents the location of the "Brightness Maximum" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case brightnessMaximum = 0x000c_0074

    /// Represents the location of the "Brightness Auto" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case brightnessAuto = 0x000c_0075

    /// Represents the location of the "Kbd Illum Up" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case kbdIllumUp = 0x000c_0079

    /// Represents the location of the "Kbd Illum Down" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case kbdIllumDown = 0x000c_007a

    /// Represents the location of the "Media Last" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaLast = 0x000c_0083

    /// Represents the location of the "Launch Phone" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchPhone = 0x000c_008c

    /// Represents the location of the "Program Guide" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case programGuide = 0x000c_008d

    /// Represents the location of the "Exit" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case exit = 0x000c_0094

    /// Represents the location of the "Channel Up" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case channelUp = 0x000c_009c

    /// Represents the location of the "Channel Down" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case channelDown = 0x000c_009d

    /// Represents the location of the "Media Play" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaPlay = 0x000c_00b0

    /// Represents the location of the "Media Pause" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaPause = 0x000c_00b1

    /// Represents the location of the "Media Record" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaRecord = 0x000c_00b2

    /// Represents the location of the "Media Fast Forward" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaFastForward = 0x000c_00b3

    /// Represents the location of the "Media Rewind" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaRewind = 0x000c_00b4

    /// Represents the location of the "Media Track Next" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaTrackNext = 0x000c_00b5

    /// Represents the location of the "Media Track Previous" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaTrackPrevious = 0x000c_00b6

    /// Represents the location of the "Media Stop" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaStop = 0x000c_00b7

    /// Represents the location of the "Eject" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case eject = 0x000c_00b8

    /// Represents the location of the "Media Play Pause" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaPlayPause = 0x000c_00cd

    /// Represents the location of the "Speech Input Toggle" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case speechInputToggle = 0x000c_00cf

    /// Represents the location of the "Bass Boost" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case bassBoost = 0x000c_00e5

    /// Represents the location of the "Media Select" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mediaSelect = 0x000c_0183

    /// Represents the location of the "Launch Word Processor" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchWordProcessor = 0x000c_0184

    /// Represents the location of the "Launch Spreadsheet" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchSpreadsheet = 0x000c_0186

    /// Represents the location of the "Launch Mail" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchMail = 0x000c_018a

    /// Represents the location of the "Launch Contacts" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchContacts = 0x000c_018d

    /// Represents the location of the "Launch Calendar" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchCalendar = 0x000c_018e

    /// Represents the location of the "Launch App2" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchApp2 = 0x000c_0192

    /// Represents the location of the "Launch App1" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchApp1 = 0x000c_0194

    /// Represents the location of the "Launch Internet Browser" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchInternetBrowser = 0x000c_0196

    /// Represents the location of the "Log Off" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case logOff = 0x000c_019c

    /// Represents the location of the "Lock Screen" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case lockScreen = 0x000c_019e

    /// Represents the location of the "Launch Control Panel" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchControlPanel = 0x000c_019f

    /// Represents the location of the "Select Task" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case selectTask = 0x000c_01a2

    /// Represents the location of the "Launch Documents" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchDocuments = 0x000c_01a7

    /// Represents the location of the "Spell Check" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case spellCheck = 0x000c_01ab

    /// Represents the location of the "Launch Keyboard Layout" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchKeyboardLayout = 0x000c_01ae

    /// Represents the location of the "Launch Screen Saver" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchScreenSaver = 0x000c_01b1

    /// Represents the location of the "Launch Audio Browser" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchAudioBrowser = 0x000c_01b7

    /// Represents the location of the "Launch Assistant" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case launchAssistant = 0x000c_01cb

    /// Represents the location of the "New Key" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case newKey = 0x000c_0201

    /// Represents the location of the "Close" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case close = 0x000c_0203

    /// Represents the location of the "Save" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case save = 0x000c_0207

    /// Represents the location of the "Print" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case print = 0x000c_0208

    /// Represents the location of the "Browser Search" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case browserSearch = 0x000c_0221

    /// Represents the location of the "Browser Home" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case browserHome = 0x000c_0223

    /// Represents the location of the "Browser Back" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case browserBack = 0x000c_0224

    /// Represents the location of the "Browser Forward" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case browserForward = 0x000c_0225

    /// Represents the location of the "Browser Stop" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case browserStop = 0x000c_0226

    /// Represents the location of the "Browser Refresh" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case browserRefresh = 0x000c_0227

    /// Represents the location of the "Browser Favorites" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case browserFavorites = 0x000c_022a

    /// Represents the location of the "Zoom In" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case zoomIn = 0x000c_022d

    /// Represents the location of the "Zoom Out" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case zoomOut = 0x000c_022e

    /// Represents the location of the "Zoom Toggle" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case zoomToggle = 0x000c_0232

    /// Represents the location of the "Redo" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case redo = 0x000c_0279

    /// Represents the location of the "Mail Reply" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mailReply = 0x000c_0289

    /// Represents the location of the "Mail Forward" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mailForward = 0x000c_028b

    /// Represents the location of the "Mail Send" key on a generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case mailSend = 0x000c_028c

    /// Represents the location of the "Keyboard Layout Select" key on a
    /// generalized keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case keyboardLayoutSelect = 0x000c_029d

    /// Represents the location of the "Show All Windows" key on a generalized
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.physicalKey] for more information.
    case showAllWindows = 0x000c_029f
}

/// A class with static values that describe the keys that are returned from
/// [RawKeyEvent.logicalKey].
///
/// These represent *logical* keys, which are keys which are interpreted in the
/// context of any modifiers, modes, or keyboard layouts which may be in effect.
///
/// This is contrast to [PhysicalKeyboardKey], which represents a physical key
/// in a particular location on the keyboard, without regard for the modifier
/// state, mode, or keyboard layout.
///
/// As an example, if you wanted to implement an app where the "Q" key "quit"
/// something, you'd want to look at the logical key to detect this, since you
/// would like to have it match the key with "Q" on it, instead of always
/// looking for "the key next to the TAB key", since on a French keyboard, the
/// key next to the TAB key has an "A" on it.
///
/// Conversely, if you wanted a game where the key next to the CAPS LOCK (the
/// "A" key on a QWERTY keyboard) moved the player to the left, you'd want to
/// look at the physical key to make sure that regardless of the character the
/// key produces, you got the key that is in that location on the keyboard.
///
/// Unlike [PhysicalKeyboardKey], the values of this enum is opaque. It should
/// not be unpacked to derive information from it, as the representation of the
/// code could change at any time.
public enum LogicalKeyboardKey: UInt, CaseIterable {
    /// Represents the logical "Space" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case space = 0x000_0000_0020

    /// Represents the logical "Exclamation" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case exclamation = 0x000_0000_0021

    /// Represents the logical "Quote" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case quote = 0x000_0000_0022

    /// Represents the logical "Number Sign" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numberSign = 0x000_0000_0023

    /// Represents the logical "Dollar" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case dollar = 0x000_0000_0024

    /// Represents the logical "Percent" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case percent = 0x000_0000_0025

    /// Represents the logical "Ampersand" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case ampersand = 0x000_0000_0026

    /// Represents the logical "Quote Single" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case quoteSingle = 0x000_0000_0027

    /// Represents the logical "Parenthesis Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case parenthesisLeft = 0x000_0000_0028

    /// Represents the logical "Parenthesis Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case parenthesisRight = 0x000_0000_0029

    /// Represents the logical "Asterisk" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case asterisk = 0x000_0000_002a

    /// Represents the logical "Add" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case add = 0x000_0000_002b

    /// Represents the logical "Comma" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case comma = 0x000_0000_002c

    /// Represents the logical "Minus" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case minus = 0x000_0000_002d

    /// Represents the logical "Period" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case period = 0x000_0000_002e

    /// Represents the logical "Slash" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case slash = 0x000_0000_002f

    /// Represents the logical "Digit 0" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit0 = 0x000_0000_0030

    /// Represents the logical "Digit 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit1 = 0x000_0000_0031

    /// Represents the logical "Digit 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit2 = 0x000_0000_0032

    /// Represents the logical "Digit 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit3 = 0x000_0000_0033

    /// Represents the logical "Digit 4" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit4 = 0x000_0000_0034

    /// Represents the logical "Digit 5" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit5 = 0x000_0000_0035

    /// Represents the logical "Digit 6" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit6 = 0x000_0000_0036

    /// Represents the logical "Digit 7" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit7 = 0x000_0000_0037

    /// Represents the logical "Digit 8" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit8 = 0x000_0000_0038

    /// Represents the logical "Digit 9" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case digit9 = 0x000_0000_0039

    /// Represents the logical "Colon" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case colon = 0x000_0000_003a

    /// Represents the logical "Semicolon" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case semicolon = 0x000_0000_003b

    /// Represents the logical "Less" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case less = 0x000_0000_003c

    /// Represents the logical "Equal" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case equal = 0x000_0000_003d

    /// Represents the logical "Greater" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case greater = 0x000_0000_003e

    /// Represents the logical "Question" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case question = 0x000_0000_003f

    /// Represents the logical "At" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case at = 0x000_0000_0040

    /// Represents the logical "Bracket Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case bracketLeft = 0x000_0000_005b

    /// Represents the logical "Backslash" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case backslash = 0x000_0000_005c

    /// Represents the logical "Bracket Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case bracketRight = 0x000_0000_005d

    /// Represents the logical "Caret" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case caret = 0x000_0000_005e

    /// Represents the logical "Underscore" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case underscore = 0x000_0000_005f

    /// Represents the logical "Backquote" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case backquote = 0x000_0000_0060

    /// Represents the logical "Key A" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyA = 0x000_0000_0061

    /// Represents the logical "Key B" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyB = 0x000_0000_0062

    /// Represents the logical "Key C" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyC = 0x000_0000_0063

    /// Represents the logical "Key D" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyD = 0x000_0000_0064

    /// Represents the logical "Key E" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyE = 0x000_0000_0065

    /// Represents the logical "Key F" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyF = 0x000_0000_0066

    /// Represents the logical "Key G" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyG = 0x000_0000_0067

    /// Represents the logical "Key H" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyH = 0x000_0000_0068

    /// Represents the logical "Key I" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyI = 0x000_0000_0069

    /// Represents the logical "Key J" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyJ = 0x000_0000_006a

    /// Represents the logical "Key K" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyK = 0x000_0000_006b

    /// Represents the logical "Key L" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyL = 0x000_0000_006c

    /// Represents the logical "Key M" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyM = 0x000_0000_006d

    /// Represents the logical "Key N" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyN = 0x000_0000_006e

    /// Represents the logical "Key O" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyO = 0x000_0000_006f

    /// Represents the logical "Key P" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyP = 0x000_0000_0070

    /// Represents the logical "Key Q" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyQ = 0x000_0000_0071

    /// Represents the logical "Key R" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyR = 0x000_0000_0072

    /// Represents the logical "Key S" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyS = 0x000_0000_0073

    /// Represents the logical "Key T" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyT = 0x000_0000_0074

    /// Represents the logical "Key U" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyU = 0x000_0000_0075

    /// Represents the logical "Key V" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyV = 0x000_0000_0076

    /// Represents the logical "Key W" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyW = 0x000_0000_0077

    /// Represents the logical "Key X" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyX = 0x000_0000_0078

    /// Represents the logical "Key Y" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyY = 0x000_0000_0079

    /// Represents the logical "Key Z" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case keyZ = 0x000_0000_007a

    /// Represents the logical "Brace Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case braceLeft = 0x000_0000_007b

    /// Represents the logical "Bar" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case bar = 0x000_0000_007c

    /// Represents the logical "Brace Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case braceRight = 0x000_0000_007d

    /// Represents the logical "Tilde" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tilde = 0x000_0000_007e

    /// Represents the logical "Unidentified" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case unidentified = 0x001_0000_0001

    /// Represents the logical "Backspace" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case backspace = 0x001_0000_0008

    /// Represents the logical "Tab" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tab = 0x001_0000_0009

    /// Represents the logical "Enter" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case enter = 0x001_0000_000d

    /// Represents the logical "Escape" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case escape = 0x001_0000_001b

    /// Represents the logical "Delete" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case delete = 0x001_0000_007f

    /// Represents the logical "Accel" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case accel = 0x001_0000_0101

    /// Represents the logical "Alt Graph" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case altGraph = 0x001_0000_0103

    /// Represents the logical "Caps Lock" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case capsLock = 0x001_0000_0104

    /// Represents the logical "Fn" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case fn = 0x001_0000_0106

    /// Represents the logical "Fn Lock" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case fnLock = 0x001_0000_0107

    /// Represents the logical "Hyper" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case hyper = 0x001_0000_0108

    /// Represents the logical "Num Lock" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numLock = 0x001_0000_010a

    /// Represents the logical "Scroll Lock" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case scrollLock = 0x001_0000_010c

    /// Represents the logical "Super" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case superKey = 0x001_0000_010e

    /// Represents the logical "Symbol" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case symbol = 0x001_0000_010f

    /// Represents the logical "Symbol Lock" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case symbolLock = 0x001_0000_0110

    /// Represents the logical "Shift Level 5" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case shiftLevel5 = 0x001_0000_0111

    /// Represents the logical "Arrow Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case arrowDown = 0x001_0000_0301

    /// Represents the logical "Arrow Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case arrowLeft = 0x001_0000_0302

    /// Represents the logical "Arrow Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case arrowRight = 0x001_0000_0303

    /// Represents the logical "Arrow Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case arrowUp = 0x001_0000_0304

    /// Represents the logical "End" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case end = 0x001_0000_0305

    /// Represents the logical "Home" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case home = 0x001_0000_0306

    /// Represents the logical "Page Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case pageDown = 0x001_0000_0307

    /// Represents the logical "Page Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case pageUp = 0x001_0000_0308

    /// Represents the logical "Clear" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case clear = 0x001_0000_0401

    /// Represents the logical "Copy" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case copy = 0x001_0000_0402

    /// Represents the logical "Cr Sel" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case crSel = 0x001_0000_0403

    /// Represents the logical "Cut" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case cut = 0x001_0000_0404

    /// Represents the logical "Erase Eof" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case eraseEof = 0x001_0000_0405

    /// Represents the logical "Ex Sel" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case exSel = 0x001_0000_0406

    /// Represents the logical "Insert" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case insert = 0x001_0000_0407

    /// Represents the logical "Paste" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case paste = 0x001_0000_0408

    /// Represents the logical "Redo" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case redo = 0x001_0000_0409

    /// Represents the logical "Undo" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case undo = 0x001_0000_040a

    /// Represents the logical "Accept" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case accept = 0x001_0000_0501

    /// Represents the logical "Again" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case again = 0x001_0000_0502

    /// Represents the logical "Attn" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case attn = 0x001_0000_0503

    /// Represents the logical "Cancel" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case cancel = 0x001_0000_0504

    /// Represents the logical "Context Menu" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case contextMenu = 0x001_0000_0505

    /// Represents the logical "Execute" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case execute = 0x001_0000_0506

    /// Represents the logical "Find" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case find = 0x001_0000_0507

    /// Represents the logical "Help" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case help = 0x001_0000_0508

    /// Represents the logical "Pause" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case pause = 0x001_0000_0509

    /// Represents the logical "Play" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case play = 0x001_0000_050a

    /// Represents the logical "Props" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case props = 0x001_0000_050b

    /// Represents the logical "Select" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case select = 0x001_0000_050c

    /// Represents the logical "Zoom In" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case zoomIn = 0x001_0000_050d

    /// Represents the logical "Zoom Out" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case zoomOut = 0x001_0000_050e

    /// Represents the logical "Brightness Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case brightnessDown = 0x001_0000_0601

    /// Represents the logical "Brightness Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case brightnessUp = 0x001_0000_0602

    /// Represents the logical "Camera" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case camera = 0x001_0000_0603

    /// Represents the logical "Eject" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case eject = 0x001_0000_0604

    /// Represents the logical "Log Off" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case logOff = 0x001_0000_0605

    /// Represents the logical "Power" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case power = 0x001_0000_0606

    /// Represents the logical "Power Off" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case powerOff = 0x001_0000_0607

    /// Represents the logical "Print Screen" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case printScreen = 0x001_0000_0608

    /// Represents the logical "Hibernate" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case hibernate = 0x001_0000_0609

    /// Represents the logical "Standby" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case standby = 0x001_0000_060a

    /// Represents the logical "Wake Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case wakeUp = 0x001_0000_060b

    /// Represents the logical "All Candidates" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case allCandidates = 0x001_0000_0701

    /// Represents the logical "Alphanumeric" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case alphanumeric = 0x001_0000_0702

    /// Represents the logical "Code Input" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case codeInput = 0x001_0000_0703

    /// Represents the logical "Compose" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case compose = 0x001_0000_0704

    /// Represents the logical "Convert" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case convert = 0x001_0000_0705

    /// Represents the logical "Final Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case finalMode = 0x001_0000_0706

    /// Represents the logical "Group First" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case groupFirst = 0x001_0000_0707

    /// Represents the logical "Group Last" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case groupLast = 0x001_0000_0708

    /// Represents the logical "Group Next" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case groupNext = 0x001_0000_0709

    /// Represents the logical "Group Previous" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case groupPrevious = 0x001_0000_070a

    /// Represents the logical "Mode Change" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case modeChange = 0x001_0000_070b

    /// Represents the logical "Next Candidate" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case nextCandidate = 0x001_0000_070c

    /// Represents the logical "Non Convert" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case nonConvert = 0x001_0000_070d

    /// Represents the logical "Previous Candidate" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case previousCandidate = 0x001_0000_070e

    /// Represents the logical "Process" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case process = 0x001_0000_070f

    /// Represents the logical "Single Candidate" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case singleCandidate = 0x001_0000_0710

    /// Represents the logical "Hangul Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case hangulMode = 0x001_0000_0711

    /// Represents the logical "Hanja Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case hanjaMode = 0x001_0000_0712

    /// Represents the logical "Junja Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case junjaMode = 0x001_0000_0713

    /// Represents the logical "Eisu" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case eisu = 0x001_0000_0714

    /// Represents the logical "Hankaku" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case hankaku = 0x001_0000_0715

    /// Represents the logical "Hiragana" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case hiragana = 0x001_0000_0716

    /// Represents the logical "Hiragana Katakana" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case hiraganaKatakana = 0x001_0000_0717

    /// Represents the logical "Kana Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case kanaMode = 0x001_0000_0718

    /// Represents the logical "Kanji Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case kanjiMode = 0x001_0000_0719

    /// Represents the logical "Katakana" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case katakana = 0x001_0000_071a

    /// Represents the logical "Romaji" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case romaji = 0x001_0000_071b

    /// Represents the logical "Zenkaku" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case zenkaku = 0x001_0000_071c

    /// Represents the logical "Zenkaku Hankaku" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case zenkakuHankaku = 0x001_0000_071d

    /// Represents the logical "F1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f1 = 0x001_0000_0801

    /// Represents the logical "F2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f2 = 0x001_0000_0802

    /// Represents the logical "F3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f3 = 0x001_0000_0803

    /// Represents the logical "F4" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f4 = 0x001_0000_0804

    /// Represents the logical "F5" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f5 = 0x001_0000_0805

    /// Represents the logical "F6" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f6 = 0x001_0000_0806

    /// Represents the logical "F7" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f7 = 0x001_0000_0807

    /// Represents the logical "F8" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f8 = 0x001_0000_0808

    /// Represents the logical "F9" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f9 = 0x001_0000_0809

    /// Represents the logical "F10" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f10 = 0x001_0000_080a

    /// Represents the logical "F11" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f11 = 0x001_0000_080b

    /// Represents the logical "F12" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f12 = 0x001_0000_080c

    /// Represents the logical "F13" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f13 = 0x001_0000_080d

    /// Represents the logical "F14" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f14 = 0x001_0000_080e

    /// Represents the logical "F15" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f15 = 0x001_0000_080f

    /// Represents the logical "F16" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f16 = 0x001_0000_0810

    /// Represents the logical "F17" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f17 = 0x001_0000_0811

    /// Represents the logical "F18" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f18 = 0x001_0000_0812

    /// Represents the logical "F19" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f19 = 0x001_0000_0813

    /// Represents the logical "F20" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f20 = 0x001_0000_0814

    /// Represents the logical "F21" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f21 = 0x001_0000_0815

    /// Represents the logical "F22" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f22 = 0x001_0000_0816

    /// Represents the logical "F23" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f23 = 0x001_0000_0817

    /// Represents the logical "F24" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case f24 = 0x001_0000_0818

    /// Represents the logical "Soft 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case soft1 = 0x001_0000_0901

    /// Represents the logical "Soft 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case soft2 = 0x001_0000_0902

    /// Represents the logical "Soft 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case soft3 = 0x001_0000_0903

    /// Represents the logical "Soft 4" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case soft4 = 0x001_0000_0904

    /// Represents the logical "Soft 5" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case soft5 = 0x001_0000_0905

    /// Represents the logical "Soft 6" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case soft6 = 0x001_0000_0906

    /// Represents the logical "Soft 7" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case soft7 = 0x001_0000_0907

    /// Represents the logical "Soft 8" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case soft8 = 0x001_0000_0908

    /// Represents the logical "Close" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case close = 0x001_0000_0a01

    /// Represents the logical "Mail Forward" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mailForward = 0x001_0000_0a02

    /// Represents the logical "Mail Reply" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mailReply = 0x001_0000_0a03

    /// Represents the logical "Mail Send" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mailSend = 0x001_0000_0a04

    /// Represents the logical "Media Play Pause" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaPlayPause = 0x001_0000_0a05

    /// Represents the logical "Media Stop" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaStop = 0x001_0000_0a07

    /// Represents the logical "Media Track Next" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaTrackNext = 0x001_0000_0a08

    /// Represents the logical "Media Track Previous" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaTrackPrevious = 0x001_0000_0a09

    /// Represents the logical "New" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case newKey = 0x001_0000_0a0a

    /// Represents the logical "Open" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case open = 0x001_0000_0a0b

    /// Represents the logical "Print" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case print = 0x001_0000_0a0c

    /// Represents the logical "Save" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case save = 0x001_0000_0a0d

    /// Represents the logical "Spell Check" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case spellCheck = 0x001_0000_0a0e

    /// Represents the logical "Audio Volume Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioVolumeDown = 0x001_0000_0a0f

    /// Represents the logical "Audio Volume Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioVolumeUp = 0x001_0000_0a10

    /// Represents the logical "Audio Volume Mute" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioVolumeMute = 0x001_0000_0a11

    /// Represents the logical "Launch Application 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchApplication2 = 0x001_0000_0b01

    /// Represents the logical "Launch Calendar" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchCalendar = 0x001_0000_0b02

    /// Represents the logical "Launch Mail" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchMail = 0x001_0000_0b03

    /// Represents the logical "Launch Media Player" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchMediaPlayer = 0x001_0000_0b04

    /// Represents the logical "Launch Music Player" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchMusicPlayer = 0x001_0000_0b05

    /// Represents the logical "Launch Application 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchApplication1 = 0x001_0000_0b06

    /// Represents the logical "Launch Screen Saver" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchScreenSaver = 0x001_0000_0b07

    /// Represents the logical "Launch Spreadsheet" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchSpreadsheet = 0x001_0000_0b08

    /// Represents the logical "Launch Web Browser" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchWebBrowser = 0x001_0000_0b09

    /// Represents the logical "Launch Web Cam" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchWebCam = 0x001_0000_0b0a

    /// Represents the logical "Launch Word Processor" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchWordProcessor = 0x001_0000_0b0b

    /// Represents the logical "Launch Contacts" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchContacts = 0x001_0000_0b0c

    /// Represents the logical "Launch Phone" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchPhone = 0x001_0000_0b0d

    /// Represents the logical "Launch Assistant" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchAssistant = 0x001_0000_0b0e

    /// Represents the logical "Launch Control Panel" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case launchControlPanel = 0x001_0000_0b0f

    /// Represents the logical "Browser Back" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case browserBack = 0x001_0000_0c01

    /// Represents the logical "Browser Favorites" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case browserFavorites = 0x001_0000_0c02

    /// Represents the logical "Browser Forward" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case browserForward = 0x001_0000_0c03

    /// Represents the logical "Browser Home" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case browserHome = 0x001_0000_0c04

    /// Represents the logical "Browser Refresh" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case browserRefresh = 0x001_0000_0c05

    /// Represents the logical "Browser Search" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case browserSearch = 0x001_0000_0c06

    /// Represents the logical "Browser Stop" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case browserStop = 0x001_0000_0c07

    /// Represents the logical "Audio Balance Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioBalanceLeft = 0x001_0000_0d01

    /// Represents the logical "Audio Balance Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioBalanceRight = 0x001_0000_0d02

    /// Represents the logical "Audio Bass Boost Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioBassBoostDown = 0x001_0000_0d03

    /// Represents the logical "Audio Bass Boost Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioBassBoostUp = 0x001_0000_0d04

    /// Represents the logical "Audio Fader Front" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioFaderFront = 0x001_0000_0d05

    /// Represents the logical "Audio Fader Rear" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioFaderRear = 0x001_0000_0d06

    /// Represents the logical "Audio Surround Mode Next" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioSurroundModeNext = 0x001_0000_0d07

    /// Represents the logical "AVR Input" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case avrInput = 0x001_0000_0d08

    /// Represents the logical "AVR Power" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case avrPower = 0x001_0000_0d09

    /// Represents the logical "Channel Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case channelDown = 0x001_0000_0d0a

    /// Represents the logical "Channel Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case channelUp = 0x001_0000_0d0b

    /// Represents the logical "Color F0 Red" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case colorF0Red = 0x001_0000_0d0c

    /// Represents the logical "Color F1 Green" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case colorF1Green = 0x001_0000_0d0d

    /// Represents the logical "Color F2 Yellow" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case colorF2Yellow = 0x001_0000_0d0e

    /// Represents the logical "Color F3 Blue" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case colorF3Blue = 0x001_0000_0d0f

    /// Represents the logical "Color F4 Grey" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case colorF4Grey = 0x001_0000_0d10

    /// Represents the logical "Color F5 Brown" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case colorF5Brown = 0x001_0000_0d11

    /// Represents the logical "Closed Caption Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case closedCaptionToggle = 0x001_0000_0d12

    /// Represents the logical "Dimmer" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case dimmer = 0x001_0000_0d13

    /// Represents the logical "Display Swap" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case displaySwap = 0x001_0000_0d14

    /// Represents the logical "Exit" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case exit = 0x001_0000_0d15

    /// Represents the logical "Favorite Clear 0" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteClear0 = 0x001_0000_0d16

    /// Represents the logical "Favorite Clear 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteClear1 = 0x001_0000_0d17

    /// Represents the logical "Favorite Clear 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteClear2 = 0x001_0000_0d18

    /// Represents the logical "Favorite Clear 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteClear3 = 0x001_0000_0d19

    /// Represents the logical "Favorite Recall 0" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteRecall0 = 0x001_0000_0d1a

    /// Represents the logical "Favorite Recall 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteRecall1 = 0x001_0000_0d1b

    /// Represents the logical "Favorite Recall 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteRecall2 = 0x001_0000_0d1c

    /// Represents the logical "Favorite Recall 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteRecall3 = 0x001_0000_0d1d

    /// Represents the logical "Favorite Store 0" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteStore0 = 0x001_0000_0d1e

    /// Represents the logical "Favorite Store 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteStore1 = 0x001_0000_0d1f

    /// Represents the logical "Favorite Store 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteStore2 = 0x001_0000_0d20

    /// Represents the logical "Favorite Store 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case favoriteStore3 = 0x001_0000_0d21

    /// Represents the logical "Guide" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case guide = 0x001_0000_0d22

    /// Represents the logical "Guide Next Day" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case guideNextDay = 0x001_0000_0d23

    /// Represents the logical "Guide Previous Day" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case guidePreviousDay = 0x001_0000_0d24

    /// Represents the logical "Info" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case info = 0x001_0000_0d25

    /// Represents the logical "Instant Replay" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case instantReplay = 0x001_0000_0d26

    /// Represents the logical "Link" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case link = 0x001_0000_0d27

    /// Represents the logical "List Program" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case listProgram = 0x001_0000_0d28

    /// Represents the logical "Live Content" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case liveContent = 0x001_0000_0d29

    /// Represents the logical "Lock" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case lock = 0x001_0000_0d2a

    /// Represents the logical "Media Apps" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaApps = 0x001_0000_0d2b

    /// Represents the logical "Media Fast Forward" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaFastForward = 0x001_0000_0d2c

    /// Represents the logical "Media Last" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaLast = 0x001_0000_0d2d

    /// Represents the logical "Media Pause" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaPause = 0x001_0000_0d2e

    /// Represents the logical "Media Play" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaPlay = 0x001_0000_0d2f

    /// Represents the logical "Media Record" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaRecord = 0x001_0000_0d30

    /// Represents the logical "Media Rewind" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaRewind = 0x001_0000_0d31

    /// Represents the logical "Media Skip" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaSkip = 0x001_0000_0d32

    /// Represents the logical "Next Favorite Channel" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case nextFavoriteChannel = 0x001_0000_0d33

    /// Represents the logical "Next User Profile" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case nextUserProfile = 0x001_0000_0d34

    /// Represents the logical "On Demand" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case onDemand = 0x001_0000_0d35

    /// Represents the logical "P In P Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case pInPDown = 0x001_0000_0d36

    /// Represents the logical "P In P Move" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case pInPMove = 0x001_0000_0d37

    /// Represents the logical "P In P Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case pInPToggle = 0x001_0000_0d38

    /// Represents the logical "P In P Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case pInPUp = 0x001_0000_0d39

    /// Represents the logical "Play Speed Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case playSpeedDown = 0x001_0000_0d3a

    /// Represents the logical "Play Speed Reset" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case playSpeedReset = 0x001_0000_0d3b

    /// Represents the logical "Play Speed Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case playSpeedUp = 0x001_0000_0d3c

    /// Represents the logical "Random Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case randomToggle = 0x001_0000_0d3d

    /// Represents the logical "Rc Low Battery" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case rcLowBattery = 0x001_0000_0d3e

    /// Represents the logical "Record Speed Next" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case recordSpeedNext = 0x001_0000_0d3f

    /// Represents the logical "Rf Bypass" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case rfBypass = 0x001_0000_0d40

    /// Represents the logical "Scan Channels Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case scanChannelsToggle = 0x001_0000_0d41

    /// Represents the logical "Screen Mode Next" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case screenModeNext = 0x001_0000_0d42

    /// Represents the logical "Settings" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case settings = 0x001_0000_0d43

    /// Represents the logical "Split Screen Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case splitScreenToggle = 0x001_0000_0d44

    /// Represents the logical "STB Input" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case stbInput = 0x001_0000_0d45

    /// Represents the logical "STB Power" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case stbPower = 0x001_0000_0d46

    /// Represents the logical "Subtitle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case subtitle = 0x001_0000_0d47

    /// Represents the logical "Teletext" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case teletext = 0x001_0000_0d48

    /// Represents the logical "TV" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tv = 0x001_0000_0d49

    /// Represents the logical "TV Input" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInput = 0x001_0000_0d4a

    /// Represents the logical "TV Power" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvPower = 0x001_0000_0d4b

    /// Represents the logical "Video Mode Next" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case videoModeNext = 0x001_0000_0d4c

    /// Represents the logical "Wink" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case wink = 0x001_0000_0d4d

    /// Represents the logical "Zoom Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case zoomToggle = 0x001_0000_0d4e

    /// Represents the logical "DVR" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case dvr = 0x001_0000_0d4f

    /// Represents the logical "Media Audio Track" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaAudioTrack = 0x001_0000_0d50

    /// Represents the logical "Media Skip Backward" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaSkipBackward = 0x001_0000_0d51

    /// Represents the logical "Media Skip Forward" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaSkipForward = 0x001_0000_0d52

    /// Represents the logical "Media Step Backward" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaStepBackward = 0x001_0000_0d53

    /// Represents the logical "Media Step Forward" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaStepForward = 0x001_0000_0d54

    /// Represents the logical "Media Top Menu" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaTopMenu = 0x001_0000_0d55

    /// Represents the logical "Navigate In" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case navigateIn = 0x001_0000_0d56

    /// Represents the logical "Navigate Next" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case navigateNext = 0x001_0000_0d57

    /// Represents the logical "Navigate Out" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case navigateOut = 0x001_0000_0d58

    /// Represents the logical "Navigate Previous" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case navigatePrevious = 0x001_0000_0d59

    /// Represents the logical "Pairing" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case pairing = 0x001_0000_0d5a

    /// Represents the logical "Media Close" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mediaClose = 0x001_0000_0d5b

    /// Represents the logical "Audio Bass Boost Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioBassBoostToggle = 0x001_0000_0e02

    /// Represents the logical "Audio Treble Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioTrebleDown = 0x001_0000_0e04

    /// Represents the logical "Audio Treble Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case audioTrebleUp = 0x001_0000_0e05

    /// Represents the logical "Microphone Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case microphoneToggle = 0x001_0000_0e06

    /// Represents the logical "Microphone Volume Down" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case microphoneVolumeDown = 0x001_0000_0e07

    /// Represents the logical "Microphone Volume Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case microphoneVolumeUp = 0x001_0000_0e08

    /// Represents the logical "Microphone Volume Mute" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case microphoneVolumeMute = 0x001_0000_0e09

    /// Represents the logical "Speech Correction List" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case speechCorrectionList = 0x001_0000_0f01

    /// Represents the logical "Speech Input Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case speechInputToggle = 0x001_0000_0f02

    /// Represents the logical "App Switch" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case appSwitch = 0x001_0000_1001

    /// Represents the logical "Call" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case call = 0x001_0000_1002

    /// Represents the logical "Camera Focus" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case cameraFocus = 0x001_0000_1003

    /// Represents the logical "End Call" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case endCall = 0x001_0000_1004

    /// Represents the logical "Go Back" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case goBack = 0x001_0000_1005

    /// Represents the logical "Go Home" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case goHome = 0x001_0000_1006

    /// Represents the logical "Headset Hook" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case headsetHook = 0x001_0000_1007

    /// Represents the logical "Last Number Redial" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case lastNumberRedial = 0x001_0000_1008

    /// Represents the logical "Notification" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case notification = 0x001_0000_1009

    /// Represents the logical "Manner Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case mannerMode = 0x001_0000_100a

    /// Represents the logical "Voice Dial" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case voiceDial = 0x001_0000_100b

    /// Represents the logical "TV 3 D Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tv3DMode = 0x001_0000_1101

    /// Represents the logical "TV Antenna Cable" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvAntennaCable = 0x001_0000_1102

    /// Represents the logical "TV Audio Description" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvAudioDescription = 0x001_0000_1103

    /// Represents the logical "TV Audio Description Mix Down" key on the
    /// keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvAudioDescriptionMixDown = 0x001_0000_1104

    /// Represents the logical "TV Audio Description Mix Up" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvAudioDescriptionMixUp = 0x001_0000_1105

    /// Represents the logical "TV Contents Menu" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvContentsMenu = 0x001_0000_1106

    /// Represents the logical "TV Data Service" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvDataService = 0x001_0000_1107

    /// Represents the logical "TV Input Component 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputComponent1 = 0x001_0000_1108

    /// Represents the logical "TV Input Component 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputComponent2 = 0x001_0000_1109

    /// Represents the logical "TV Input Composite 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputComposite1 = 0x001_0000_110a

    /// Represents the logical "TV Input Composite 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputComposite2 = 0x001_0000_110b

    /// Represents the logical "TV Input HDMI 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputHDMI1 = 0x001_0000_110c

    /// Represents the logical "TV Input HDMI 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputHDMI2 = 0x001_0000_110d

    /// Represents the logical "TV Input HDMI 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputHDMI3 = 0x001_0000_110e

    /// Represents the logical "TV Input HDMI 4" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputHDMI4 = 0x001_0000_110f

    /// Represents the logical "TV Input VGA 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvInputVGA1 = 0x001_0000_1110

    /// Represents the logical "TV Media Context" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvMediaContext = 0x001_0000_1111

    /// Represents the logical "TV Network" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvNetwork = 0x001_0000_1112

    /// Represents the logical "TV Number Entry" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvNumberEntry = 0x001_0000_1113

    /// Represents the logical "TV Radio Service" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvRadioService = 0x001_0000_1114

    /// Represents the logical "TV Satellite" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvSatellite = 0x001_0000_1115

    /// Represents the logical "TV Satellite BS" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvSatelliteBS = 0x001_0000_1116

    /// Represents the logical "TV Satellite CS" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvSatelliteCS = 0x001_0000_1117

    /// Represents the logical "TV Satellite Toggle" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvSatelliteToggle = 0x001_0000_1118

    /// Represents the logical "TV Terrestrial Analog" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvTerrestrialAnalog = 0x001_0000_1119

    /// Represents the logical "TV Terrestrial Digital" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvTerrestrialDigital = 0x001_0000_111a

    /// Represents the logical "TV Timer" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case tvTimer = 0x001_0000_111b

    /// Represents the logical "Key 11" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case key11 = 0x001_0000_1201

    /// Represents the logical "Key 12" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case key12 = 0x001_0000_1202

    /// Represents the logical "Suspend" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case suspend = 0x002_0000_0000

    /// Represents the logical "Resume" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case resume = 0x002_0000_0001

    /// Represents the logical "Sleep" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case sleep = 0x002_0000_0002

    /// Represents the logical "Abort" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case abort = 0x002_0000_0003

    /// Represents the logical "Lang 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case lang1 = 0x002_0000_0010

    /// Represents the logical "Lang 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case lang2 = 0x002_0000_0011

    /// Represents the logical "Lang 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case lang3 = 0x002_0000_0012

    /// Represents the logical "Lang 4" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case lang4 = 0x002_0000_0013

    /// Represents the logical "Lang 5" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case lang5 = 0x002_0000_0014

    /// Represents the logical "Intl Backslash" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case intlBackslash = 0x002_0000_0020

    /// Represents the logical "Intl Ro" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case intlRo = 0x002_0000_0021

    /// Represents the logical "Intl Yen" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case intlYen = 0x002_0000_0022

    /// Represents the logical "Control Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case controlLeft = 0x002_0000_0100

    /// Represents the logical "Control Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case controlRight = 0x002_0000_0101

    /// Represents the logical "Shift Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case shiftLeft = 0x002_0000_0102

    /// Represents the logical "Shift Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case shiftRight = 0x002_0000_0103

    /// Represents the logical "Alt Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case altLeft = 0x002_0000_0104

    /// Represents the logical "Alt Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case altRight = 0x002_0000_0105

    /// Represents the logical "Meta Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case metaLeft = 0x002_0000_0106

    /// Represents the logical "Meta Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case metaRight = 0x002_0000_0107

    /// Represents the logical "Control" key on the keyboard.
    ///
    /// This key represents the union of the keys {controlLeft, controlRight} when
    /// comparing keys. This key will never be generated directly, its main use is
    /// in defining key maps.
    case control = 0x002_0000_01f0

    /// Represents the logical "Shift" key on the keyboard.
    ///
    /// This key represents the union of the keys {shiftLeft, shiftRight} when
    /// comparing keys. This key will never be generated directly, its main use is
    /// in defining key maps.
    case shift = 0x002_0000_01f2

    /// Represents the logical "Alt" key on the keyboard.
    ///
    /// This key represents the union of the keys {altLeft, altRight} when
    /// comparing keys. This key will never be generated directly, its main use is
    /// in defining key maps.
    case alt = 0x002_0000_01f4

    /// Represents the logical "Meta" key on the keyboard.
    ///
    /// This key represents the union of the keys {metaLeft, metaRight} when
    /// comparing keys. This key will never be generated directly, its main use is
    /// in defining key maps.
    case meta = 0x002_0000_01f6

    /// Represents the logical "Numpad Enter" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadEnter = 0x002_0000_020d

    /// Represents the logical "Numpad Paren Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadParenLeft = 0x002_0000_0228

    /// Represents the logical "Numpad Paren Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadParenRight = 0x002_0000_0229

    /// Represents the logical "Numpad Multiply" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadMultiply = 0x002_0000_022a

    /// Represents the logical "Numpad Add" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadAdd = 0x002_0000_022b

    /// Represents the logical "Numpad Comma" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadComma = 0x002_0000_022c

    /// Represents the logical "Numpad Subtract" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadSubtract = 0x002_0000_022d

    /// Represents the logical "Numpad Decimal" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadDecimal = 0x002_0000_022e

    /// Represents the logical "Numpad Divide" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadDivide = 0x002_0000_022f

    /// Represents the logical "Numpad 0" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad0 = 0x002_0000_0230

    /// Represents the logical "Numpad 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad1 = 0x002_0000_0231

    /// Represents the logical "Numpad 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad2 = 0x002_0000_0232

    /// Represents the logical "Numpad 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad3 = 0x002_0000_0233

    /// Represents the logical "Numpad 4" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad4 = 0x002_0000_0234

    /// Represents the logical "Numpad 5" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad5 = 0x002_0000_0235

    /// Represents the logical "Numpad 6" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad6 = 0x002_0000_0236

    /// Represents the logical "Numpad 7" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad7 = 0x002_0000_0237

    /// Represents the logical "Numpad 8" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad8 = 0x002_0000_0238

    /// Represents the logical "Numpad 9" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpad9 = 0x002_0000_0239

    /// Represents the logical "Numpad Equal" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case numpadEqual = 0x002_0000_023d

    /// Represents the logical "Game Button 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton1 = 0x002_0000_0301

    /// Represents the logical "Game Button 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton2 = 0x002_0000_0302

    /// Represents the logical "Game Button 3" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton3 = 0x002_0000_0303

    /// Represents the logical "Game Button 4" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton4 = 0x002_0000_0304

    /// Represents the logical "Game Button 5" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton5 = 0x002_0000_0305

    /// Represents the logical "Game Button 6" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton6 = 0x002_0000_0306

    /// Represents the logical "Game Button 7" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton7 = 0x002_0000_0307

    /// Represents the logical "Game Button 8" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton8 = 0x002_0000_0308

    /// Represents the logical "Game Button 9" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton9 = 0x002_0000_0309

    /// Represents the logical "Game Button 10" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton10 = 0x002_0000_030a

    /// Represents the logical "Game Button 11" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton11 = 0x002_0000_030b

    /// Represents the logical "Game Button 12" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton12 = 0x002_0000_030c

    /// Represents the logical "Game Button 13" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton13 = 0x002_0000_030d

    /// Represents the logical "Game Button 14" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton14 = 0x002_0000_030e

    /// Represents the logical "Game Button 15" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton15 = 0x002_0000_030f

    /// Represents the logical "Game Button 16" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButton16 = 0x002_0000_0310

    /// Represents the logical "Game Button A" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonA = 0x002_0000_0311

    /// Represents the logical "Game Button B" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonB = 0x002_0000_0312

    /// Represents the logical "Game Button C" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonC = 0x002_0000_0313

    /// Represents the logical "Game Button Left 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonLeft1 = 0x002_0000_0314

    /// Represents the logical "Game Button Left 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonLeft2 = 0x002_0000_0315

    /// Represents the logical "Game Button Mode" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonMode = 0x002_0000_0316

    /// Represents the logical "Game Button Right 1" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonRight1 = 0x002_0000_0317

    /// Represents the logical "Game Button Right 2" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonRight2 = 0x002_0000_0318

    /// Represents the logical "Game Button Select" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonSelect = 0x002_0000_0319

    /// Represents the logical "Game Button Start" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonStart = 0x002_0000_031a

    /// Represents the logical "Game Button Thumb Left" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonThumbLeft = 0x002_0000_031b

    /// Represents the logical "Game Button Thumb Right" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonThumbRight = 0x002_0000_031c

    /// Represents the logical "Game Button X" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonX = 0x002_0000_031d

    /// Represents the logical "Game Button Y" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonY = 0x002_0000_031e

    /// Represents the logical "Game Button Z" key on the keyboard.
    ///
    /// See the function [RawKeyEvent.logicalKey] for more information.
    case gameButtonZ = 0x002_0000_031f
}

// A map of keys to the pseudo-key synonym for that key.
private let _synonyms: [LogicalKeyboardKey: Set<LogicalKeyboardKey>] = [
    .shiftLeft: [.shift],
    .shiftRight: [.shift],
    .metaLeft: [.meta],
    .metaRight: [.meta],
    .altLeft: [.alt],
    .altRight: [.alt],
    .controlLeft: [.control],
    .controlRight: [.control],
]

// A map of pseudo-key to the set of keys that are synonyms for that pseudo-key.
private let _reverseSynonyms: [LogicalKeyboardKey: Set<LogicalKeyboardKey>] = [
    .shift: [.shiftLeft, .shiftRight],
    .meta: [.metaLeft, .metaRight],
    .alt: [.altLeft, .altRight],
    .control: [.controlLeft, .controlRight],
]

extension LogicalKeyboardKey {
    /// Takes a set of keys, and returns the same set, but with any keys that have
    /// synonyms replaced.
    ///
    /// It is used, for example, to take sets of keys with members like
    /// [controlRight] and [controlLeft] and convert that set to contain just
    /// [control], so that the question "is any control key down?" can be asked.
    public static func collapseSynonyms(_ input: Set<LogicalKeyboardKey>) -> Set<LogicalKeyboardKey>
    {
        return Set(
            input.flatMap { element in
                return _synonyms[element] ?? [element]
            }
        )
    }

    /// Returns the given set with any pseudo-keys expanded into their synonyms.
    ///
    /// It is used, for example, to take sets of keys with members like [control]
    /// and [shift] and convert that set to contain [controlLeft], [controlRight],
    /// [shiftLeft], and [shiftRight].
    public static func expandSynonyms(_ input: Set<LogicalKeyboardKey>) -> Set<LogicalKeyboardKey> {
        return Set(
            input.flatMap { element in
                return _reverseSynonyms[element] ?? [element]
            }
        )
    }
}
