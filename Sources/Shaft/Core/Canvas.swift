// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A canvas is the interface for drawing operations. It is used to draw
/// primitives, images, and other canvases. The drawing operations are either
/// immediate or recorded into a display list depending on the actual
/// implementation.
public protocol Canvas: DlOpReceiver {
    func getSaveCount() -> Int
}

/// Canvas directly drawing to a surface. This type of canvas has additional
/// methods for submitting painting commands to the underlying graphics API.
public protocol DirectCanvas: Canvas {
    /// The physical size of the canvas in pixels.
    var size: ISize { get }

    /// Submits painting commands to the underlying graphics API.
    func flush()
}

extension Canvas {
    public func drawDisplayList(_ displayList: DisplayList) {
        displayList.dispatch(to: self)
    }
}

public class RecordingCanvas: DisplayListBuilder, Canvas {
    public func getSaveCount() -> Int {
        1
    }
}
