// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Whether the gesture was accepted or rejected.
public enum GestureDisposition {
    /// This gesture was accepted as the interpretation of the user's input.
    case accepted

    /// This gesture was rejected as the interpretation of the user's input.
    case rejected
}

/// Represents an object participating in an arena.
///
/// Receives callbacks from the GestureArena to notify the object when it wins
/// or loses a gesture negotiation. Exactly one of ``acceptGesture`` or
/// ``rejectGesture`` will be called for each arena this member was added to,
/// regardless of what caused the arena to be resolved. For example, if a
/// member resolves the arena itself, that member still receives an
/// ``acceptGesture`` callback.
public protocol GestureArenaMember: AnyObject {
    /// Called when this member wins the arena for the given pointer id.
    func acceptGesture(pointer: Int)

    /// Called when this member loses the arena for the given pointer id.
    func rejectGesture(pointer: Int)
}

/// An interface to pass information to an arena.
///
/// A given ``GestureArenaMember`` can have multiple entries in multiple arenas
/// with different pointer ids.
public struct GestureArenaEntry {
    let arena: GestureArenaManager
    let pointer: Int
    let member: GestureArenaMember

    /// Call this member to claim victory (with accepted) or admit defeat (with rejected).
    ///
    /// It's fine to attempt to resolve a gesture recognizer for an arena that is
    /// already resolved.
    public func resolve(_ disposition: GestureDisposition) {
        arena.resolve(pointer, member, disposition)
    }
}

private class GestureArena {
    var members: [GestureArenaMember] = []
    var isOpen = true
    var isHeld = false
    var hasPendingSweep = false

    /// If a member attempts to win while the arena is still open, it becomes the
    /// "eager winner". We look for an eager winner when closing the arena to new
    /// participants, and if there is one, we resolve the arena in its favor at
    /// that time.
    var eagerWinner: GestureArenaMember?

    func add(_ member: GestureArenaMember) {
        assert(isOpen)
        members.append(member)
    }

    var description: String {
        if members.isEmpty {
            return "<empty>"
        } else {
            return members.map { member in
                if member === eagerWinner {
                    return "\(member) (eager winner)"
                } else {
                    return "\(member)"
                }
            }.joined(separator: ", ")
        }
    }
}

public final class GestureArenaManager {
    private var arenas: [Int: GestureArena] = [:]

    /// Adds a new member (e.g., gesture recognizer) to the arena.
    public func add(_ pointer: Int, _ member: GestureArenaMember) -> GestureArenaEntry {
        let arena = arenas.putIfAbsent(pointer, { GestureArena() })
        arena.add(member)
        return GestureArenaEntry(arena: self, pointer: pointer, member: member)
    }

    /// Prevents new members from entering the arena.
    ///
    /// Called after the framework has finished dispatching the pointer down event.
    public func close(_ pointer: Int) {
        guard let arena = arenas[pointer] else {
            return
        }
        arena.isOpen = false
        tryToResolveArena(pointer, arena)
    }

    /// Forces resolution of the arena, giving the win to the first member.
    ///
    /// Sweep is typically after all the other processing for a ``PointerUpEvent``
    /// have taken place. It ensures that multiple passive gestures do not cause a
    /// stalemate that prevents the user from interacting with the app.
    ///
    /// Recognizers that wish to delay resolving an arena past ``PointerUpEvent``
    /// should call ``hold`` to delay sweep until ``release`` is called.
    ///
    /// See also:
    ///
    ///  * ``hold``
    ///  * ``release``
    public func sweep(_ pointer: Int) {
        guard let state = arenas[pointer] else {
            return  // This arena either never existed or has been resolved.
        }
        assert(!state.isOpen)
        if state.isHeld {
            state.hasPendingSweep = true
            return  // This arena is being held for a long-lived member.
        }
        arenas.removeValue(forKey: pointer)
        if !state.members.isEmpty {
            // First member wins.
            state.members.first?.acceptGesture(pointer: pointer)
            // Give all the other members the bad news.
            for i in 1..<state.members.count {
                state.members[i].rejectGesture(pointer: pointer)
            }
        }
    }

    /// Prevents the arena from being swept.
    ///
    /// Typically, a winner is chosen in an arena after all the other
    /// ``PointerUpEvent`` processing by [sweep]. If a recognizer wishes to delay
    /// resolving an arena past ``PointerUpEvent``, the recognizer can ``hold`` the
    /// arena open using this function. To release such a hold and let the arena
    /// resolve, call ``release``.
    ///
    /// See also:
    ///
    ///  * [sweep]
    ///  * ``release``
    public func hold(_ pointer: Int) {
        guard let state = arenas[pointer] else {
            return  // This arena either never existed or has been resolved.
        }
        state.isHeld = true
    }

    /// Releases a hold, allowing the arena to be swept.
    ///
    /// If a sweep was attempted on a held arena, the sweep will be done
    /// on release.
    ///
    /// See also:
    ///
    ///  * [sweep]
    ///  * ``hold``
    public func release(_ pointer: Int) {
        guard let state = arenas[pointer] else {
            return  // This arena either never existed or has been resolved.
        }
        state.isHeld = false
        if state.hasPendingSweep {
            sweep(pointer)
        }
    }

    /// Reject or accept a gesture recognizer.
    ///
    /// This is called by calling [GestureArenaEntry.resolve] on the object returned from [add].
    fileprivate func resolve(
        _ pointer: Int,
        _ member: GestureArenaMember,
        _ disposition: GestureDisposition
    ) {
        guard let state = arenas[pointer] else {
            return  // This arena has already resolved.
        }
        switch disposition {
        case .rejected:
            state.members.removeAll(where: { $0 === member })
            member.rejectGesture(pointer: pointer)
            if !state.isOpen {
                tryToResolveArena(pointer, state)
            }
        case .accepted:
            if state.isOpen {
                state.eagerWinner = member
            } else {
                resolveInFavorOf(pointer, state, member)
            }
        }
    }

    private func tryToResolveArena(_ pointer: Int, _ state: GestureArena) {
        assert(arenas[pointer] === state)
        assert(!state.isOpen)
        if state.members.count == 1 {
            backend.postTask {
                self.resolveByDefault(pointer, state)
            }
        } else if state.members.isEmpty {
            arenas.removeValue(forKey: pointer)
        } else if let eagerWinner = state.eagerWinner {
            resolveInFavorOf(pointer, state, eagerWinner)
        }
    }

    private func resolveByDefault(_ pointer: Int, _ state: GestureArena) {
        if arenas[pointer] == nil {
            return  // This arena has already resolved.
        }
        assert(arenas[pointer] === state)
        assert(!state.isOpen)
        let members = state.members
        assert(members.count == 1)
        arenas.removeValue(forKey: pointer)
        members.first?.acceptGesture(pointer: pointer)
    }

    private func resolveInFavorOf(
        _ pointer: Int,
        _ state: GestureArena,
        _ member: GestureArenaMember
    ) {
        assert(arenas[pointer] === state)
        assert(state.eagerWinner == nil || state.eagerWinner === member)
        assert(!state.isOpen)
        arenas.removeValue(forKey: pointer)
        for rejectedMember in state.members {
            if rejectedMember !== member {
                rejectedMember.rejectGesture(pointer: pointer)
            }
        }
        member.acceptGesture(pointer: pointer)
    }
}
