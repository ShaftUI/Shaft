import CSkia

public class SkiaPath: Path {
    internal var skPath = SkPath()

    public func moveTo(_ x: Float, _ y: Float) {
        sk_path_move_to(&skPath, x, y)
    }

    public func lineTo(_ x: Float, _ y: Float) {
        sk_path_line_to(&skPath, x, y)
    }

    public func reset() {
        sk_path_reset(&skPath)
    }
}
