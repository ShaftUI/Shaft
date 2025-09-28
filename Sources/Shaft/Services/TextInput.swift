// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import SwiftMath

/// The binding of the text input ability of the view.
public class TextInput {
    internal init(_ view: NativeView) {
        self.view = view
        view.onTextEditing = handleTextEditing
        view.onTextComposed = handleTextComposed
        view.onTextInputClosed = handleTextInputClosed
    }

    public weak var view: NativeView!

    /// The client that is currently has the text input focus.
    fileprivate var currentConnection: TextInputConnection?

    public func attach(_ client: TextInputClient) -> TextInputConnection {
        if !view.textInputActive {
            view.startTextInput()
        }
        let connection = TextInputConnection(owner: self, client: client)
        currentConnection = connection
        return connection
    }

    private func handleTextEditing(delta: TextEditingDelta) {
        currentConnection?.client?.onTextEditing(delta: delta)
    }

    private func handleTextComposed(text: String) {
        currentConnection?.client?.onTextComposed(text: text)
    }

    private func handleTextInputClosed() {
        currentConnection?.client?.onTextInputClosed()
        currentConnection = nil
    }

    fileprivate func setComposingRect(_ rect: Rect) {
        view.setComposingRect(rect)
    }

    fileprivate func setEditableSizeAndTransform(_ size: Size, _ transform: Matrix4x4f) {
        view.setEditableSizeAndTransform(size, transform)
    }

    /// Closes the current TextInputConnection.
    fileprivate func deactivate() {
        currentConnection = nil
        scheduleClose()
    }

    private var closeTaskScheduled = false

    // Schedule a deferred task that hides the text input. If someone else
    // shows the keyboard during this update cycle, then the task will do
    // nothing.
    private func scheduleClose() {
        if closeTaskScheduled {
            return
        }
        closeTaskScheduled = true

        backend.postTask {
            self.closeTaskScheduled = false
            if self.currentConnection == nil {
                self.view.stopTextInput()
            }
        }
    }
}

/// An interface to receive information from [TextInput].
public protocol TextInputClient: AnyObject {
    /// Called when the text being edited changes.
    func onTextEditing(delta: any TextEditingDelta)

    /// Called when the text has been composed and committed.
    func onTextComposed(text: String)

    /// Called when the text input connection is closed.
    func onTextInputClosed()
}

/// An interface for interacting with a text input control.
public class TextInputConnection {
    fileprivate init(owner: TextInput, client: TextInputClient) {
        self.owner = owner
        self.client = client
    }

    private var owner: TextInput

    /// The client that created this connection.
    fileprivate weak var client: TextInputClient?

    /// Whether the text input connection is currently active and receiving
    /// events.
    public var isActive: Bool {
        return owner.currentConnection === self
    }

    /// Send the smallest rect that covers the text in the client that's
    /// currently being composed.
    ///
    /// This information is used for positioning the IME candidates menu on each
    /// platform.
    public func setComposingRect(_ rect: Rect) {
        assert(isActive)
        owner.setComposingRect(rect)
    }

    private var cachedSize: Size?
    private var cachedTransform: Matrix4x4f?

    /// Send the size and transform of the editable text to engine.
    ///
    /// 1. [size]: size of the render editable box.
    ///
    /// 2. [transform]: a matrix that maps the local paint coordinate system
    ///                 to the [PipelineOwner.rootNode].
    public func setEditableSizeAndTransform(_ size: Size, _ transform: Matrix4x4f) {
        if size != cachedSize || transform != cachedTransform {
            cachedSize = size
            cachedTransform = transform
            owner.setEditableSizeAndTransform(size, transform)
        }
    }
    /// Stop interacting with the text input control.
    ///
    /// After calling this method, the text input control might disappear if no
    /// other client attaches to it within this animation frame.
    public func close() {
        if isActive {
            owner.deactivate()
        }
        assert(!isActive)
    }
}
