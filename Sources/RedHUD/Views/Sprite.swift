import Geometry
import GeometryAlgorithms
import RedECS

/// Draws a texture-map frame (or a whole texture) at its native size, or an
/// animation frame chosen by a time the game derives from its state — the
/// HUD is rebuilt every frame, so animation progress comes in from outside
/// rather than being clocked here. Requires the texture's `TextureMap` to be
/// loaded; without it (or with an unknown frame/animation) the sprite
/// occupies no space, like a `Text` with no font.
public struct Sprite: BuiltinHUDView {
    public enum Source: Equatable {
        case texture(TextureReference)
        case animation(textureId: TextureId, name: String, time: Double)
    }

    public var source: Source

    public init(_ textureId: TextureId, frame frameId: String? = nil) {
        self.source = .texture(TextureReference(textureId: textureId, frameId: frameId))
    }

    /// `time` is in seconds and wraps around the animation's total duration,
    /// so a game clock or state-derived elapsed time loops the animation.
    public init(_ textureId: TextureId, animation name: String, time: Double) {
        self.source = .animation(textureId: textureId, name: name, time: time)
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        guard let resolved = resolveFrame(context) else {
            return HUDNode(frame: Rect(origin: .zero, size: .zero))
        }
        let renderRect = Rect(origin: .zero, size: resolved.textureRect.size)
        guard let renderTris = try? renderRect.triangulate(),
              let textureTris = try? resolved.textureRect.triangulate() else {
            return HUDNode(frame: renderRect)
        }
        // Texture quads use the engine's y-up math (shared with sprites and
        // glyphs); flip into local y-down space like Text does.
        let flip = Matrix3.identity
            .translatedBy(tx: 0, ty: renderRect.size.height)
            .scaledBy(sx: 1, sy: -1)
        return HUDNode(
            frame: renderRect,
            groups: [
                RenderGroup(
                    triangles: zip(renderTris, textureTris).map {
                        RenderTriangle(triangle: $0, textureTriangle: $1)
                    },
                    transformMatrix: flip,
                    fragmentType: .texture(resolved.textureId),
                    zIndex: 0,
                    opacity: context.opacity
                )
            ]
        )
    }

    private struct ResolvedFrame {
        var textureId: TextureId
        /// Atlas coordinates, y-up (origin bottom-left of the page).
        var textureRect: Rect
    }

    private func resolveFrame(_ context: HUDRenderContext) -> ResolvedFrame? {
        guard let resourceManager = context.resourceManager else { return nil }
        let reference: TextureReference
        switch source {
        case .texture(let ref):
            reference = ref
        case .animation(let textureId, let name, let time):
            guard let animations = resourceManager.animationsForTexture(textureId),
                  let animation = animations[name],
                  let frame = animation.frame(at: time) else {
                return nil
            }
            reference = TextureReference(textureId: textureId, frameId: frame.name)
        }

        guard let textureMap = resourceManager.getTexture(textureId: reference.textureId) else {
            return nil
        }
        if let frameId = reference.frameId {
            guard let frame = textureMap.frames.first(where: { $0.filename == frameId }) else {
                return nil
            }
            return ResolvedFrame(
                textureId: reference.textureId,
                textureRect: Rect(
                    x: frame.frame.x,
                    y: textureMap.meta.size.h - frame.frame.y - frame.frame.h,
                    width: frame.frame.w,
                    height: frame.frame.h
                )
            )
        }
        return ResolvedFrame(
            textureId: reference.textureId,
            textureRect: Rect(x: 0, y: 0, width: textureMap.meta.size.w, height: textureMap.meta.size.h)
        )
    }
}

public extension SpriteAnimationDictionary.Animation {
    /// The frame playing at `time` seconds since the animation started,
    /// looping over the total duration. Frame durations are in milliseconds
    /// (matching `SpriteAnimation`).
    func frame(at time: Double) -> Frame? {
        guard !frames.isEmpty else { return nil }
        let total = frames.reduce(0) { $0 + $1.duration / 1000 }
        guard total > 0 else { return frames[0] }
        var remaining = time.truncatingRemainder(dividingBy: total)
        if remaining < 0 { remaining += total }
        for frame in frames {
            remaining -= frame.duration / 1000
            if remaining < 0 { return frame }
        }
        return frames[frames.count - 1]
    }
}
