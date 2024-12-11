// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// 
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Any changes to this file should be reflected in the debugAssertAllGesturesVarsUnset()
// function below.

/// Whether to print the results of each hit test to the console.
///
/// When this is set, in debug mode, any time a hit test is triggered by the
/// [GestureBinding] the results are dumped to the console.
///
/// This has no effect in release builds.
var debugPrintHitTestResults = false

/// Whether to print the details of each mouse hover event to the console.
///
/// When this is set, in debug mode, any time a mouse hover event is triggered
/// by the [GestureBinding], the results are dumped to the console.
///
/// This has no effect in release builds, and only applies to mouse hover
/// events.
var debugPrintMouseHoverEvents = false

/// Prints information about gesture recognizers and gesture arenas.
///
/// This flag only has an effect in debug mode.
///
/// See also:
///
///  * [GestureArenaManager], the class that manages gesture arenas.
///  * [debugPrintRecognizerCallbacksTrace], for debugging issues with
///    gesture recognizers.
var debugPrintGestureArenaDiagnostics = false

/// Logs a message every time a gesture recognizer callback is invoked.
///
/// This flag only has an effect in debug mode.
///
/// This is specifically used by [GestureRecognizer.invokeCallback]. Gesture
/// recognizers that do not use this method to invoke callbacks may not honor
/// the [debugPrintRecognizerCallbacksTrace] flag.
///
/// See also:
///
///  * [debugPrintGestureArenaDiagnostics], for debugging issues with gesture
///    arenas.
var debugPrintRecognizerCallbacksTrace = false

/// Whether to print the resampling margin to the console.
///
/// When this is set, in debug mode, any time resampling is triggered by the
/// [GestureBinding] the resampling margin is dumped to the console. The
/// resampling margin is the delta between the time of the last received
/// touch event and the current sample time. Positive value indicates that
/// resampling is effective and the resampling offset can potentially be
/// reduced for improved latency. Negative value indicates that resampling
/// is failing and resampling offset needs to be increased for smooth
/// touch event processing.
///
/// This has no effect in release builds.
var debugPrintResamplingMargin = false
