import SwiftSDL3

public final class SDLCursor: NativeMouseCursor {
    /// Creates a new SDL cursor from the given system cursor.
    public init?(fromSystem cursor: SystemMouseCursor) {
        let cursorType: SDL_SystemCursor

        switch cursor {
        case .basic:
            cursorType = SDL_SYSTEM_CURSOR_DEFAULT
        case .text:
            cursorType = SDL_SYSTEM_CURSOR_TEXT
        case .wait:
            cursorType = SDL_SYSTEM_CURSOR_WAIT
        case .precise:
            cursorType = SDL_SYSTEM_CURSOR_CROSSHAIR
        case .progress:
            cursorType = SDL_SYSTEM_CURSOR_PROGRESS
        case .resizeUpLeftDownRight:
            cursorType = SDL_SYSTEM_CURSOR_NWSE_RESIZE
        case .resizeUpRightDownLeft:
            cursorType = SDL_SYSTEM_CURSOR_NESW_RESIZE
        case .resizeLeftRight:
            cursorType = SDL_SYSTEM_CURSOR_EW_RESIZE
        case .resizeUpDown:
            cursorType = SDL_SYSTEM_CURSOR_NS_RESIZE
        case .move:
            cursorType = SDL_SYSTEM_CURSOR_MOVE
        case .forbidden:
            cursorType = SDL_SYSTEM_CURSOR_NOT_ALLOWED
        case .click:
            cursorType = SDL_SYSTEM_CURSOR_POINTER
        case .resizeUpLeft:
            cursorType = SDL_SYSTEM_CURSOR_NW_RESIZE
        case .resizeUp:
            cursorType = SDL_SYSTEM_CURSOR_N_RESIZE
        case .resizeUpRight:
            cursorType = SDL_SYSTEM_CURSOR_NE_RESIZE
        case .resizeRight:
            cursorType = SDL_SYSTEM_CURSOR_E_RESIZE
        case .resizeDownRight:
            cursorType = SDL_SYSTEM_CURSOR_SE_RESIZE
        case .resizeDown:
            cursorType = SDL_SYSTEM_CURSOR_S_RESIZE
        case .resizeDownLeft:
            cursorType = SDL_SYSTEM_CURSOR_SW_RESIZE
        case .resizeLeft:
            cursorType = SDL_SYSTEM_CURSOR_W_RESIZE
        default:
            return nil
        }

        guard let instance = SDL_CreateSystemCursor(cursorType) else {
            return nil
        }

        self.sdlCursor = instance
    }

    deinit {
        SDL_DestroyCursor(sdlCursor)
    }

    private let sdlCursor: OpaquePointer

    public func activate() {
        let ok = SDL_SetCursor(sdlCursor)
        assert(ok == true, "Failed to set cursor")
    }
}
