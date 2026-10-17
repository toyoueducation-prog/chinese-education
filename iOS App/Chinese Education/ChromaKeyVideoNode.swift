import SpriteKit
import AVFoundation
import CoreImage
import UIKit
import CoreVideo

/// Plays character clips on an `SKSpriteNode` while discarding flat chroma green `#00FF00`.
///
/// Plain `SKVideoNode` + H.264 cannot store alpha. An earlier SKShader keyed on
/// `g - max(r,b)`, which also punched holes in the explorer's olive vest. This node
/// instead keys by **RGB distance to `#00FF00`** (screen ≈0.11, vest ≈0.5+), softens
/// the edge, despills fringe green, and uploads premultiplied RGBA textures SpriteKit
/// can composite.
///
/// Performance: walk/companion clips are ~960². Per-frame CPU keying + new `SKTexture`
/// on the main thread stalled the game loop. Frames are **pre-keyed once** at a display-
/// sized resolution, cached by URL, then played back with `SKAction` (no live keying).
final class ChromaKeyVideoNode: SKSpriteNode {
    private(set) var player: AVPlayer
    private var endObserver: NSObjectProtocol?
    private let loops: Bool
    private let videoURL: URL
    private let animateActionKey = "chromaKeyCachedAnim"
    private var wantsPlaying = false

    /// Match tested still-frame params: screen clears, olive vest/pants stay opaque.
    private let keySimilarity: Float = 0.32
    private let keyBlend: Float = 0.10
    /// Source clips are 960² but drawn ~60pt; baking at 128² keeps edges clean on 3×.
    private let maxBakeDimension: Int = 128

    private struct CachedClip {
        let textures: [SKTexture]
        let timePerFrame: TimeInterval
    }

    private static let cacheLock = NSLock()
    private static var clipCache: [String: CachedClip] = [:]
    private static var bakingKeys = Set<String>()

    init(url: URL, size: CGSize, loops: Bool = true, muted: Bool = true) {
        self.loops = loops
        self.videoURL = url
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.volume = muted ? 0 : 1
        player.actionAtItemEnd = .pause
        self.player = player

        super.init(texture: nil, color: .clear, size: size)
        blendMode = .alpha
        name = "chromaKeyVideo"

        // Warm the shared texture cache as soon as the node exists (walk starts later).
        Self.preload(url: url, maxBakeDimension: maxBakeDimension, similarity: keySimilarity, blend: keyBlend)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stop()
    }

    func play() {
        wantsPlaying = true
        if let clip = Self.cachedClip(for: videoURL) {
            runCachedAnimation(clip)
            return
        }
        Self.preload(url: videoURL, maxBakeDimension: maxBakeDimension, similarity: keySimilarity, blend: keyBlend) { [weak self] clip in
            guard let self, self.wantsPlaying, let clip else { return }
            self.runCachedAnimation(clip)
        }
    }

    func pause() {
        wantsPlaying = false
        removeAction(forKey: animateActionKey)
        player.pause()
    }

    func stop() {
        wantsPlaying = false
        removeAction(forKey: animateActionKey)
        player.pause()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    override func removeFromParent() {
        stop()
        super.removeFromParent()
    }

    // MARK: - Cached playback

    private func runCachedAnimation(_ clip: CachedClip) {
        removeAction(forKey: animateActionKey)
        guard !clip.textures.isEmpty else { return }
        texture = clip.textures[0]
        let animate = SKAction.animate(with: clip.textures, timePerFrame: clip.timePerFrame, resize: false, restore: false)
        let action = loops ? SKAction.repeatForever(animate) : animate
        run(action, withKey: animateActionKey)
    }

    private static func cachedClip(for url: URL) -> CachedClip? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return clipCache[url.absoluteString]
    }

    private static func preload(
        url: URL,
        maxBakeDimension: Int,
        similarity: Float,
        blend: Float,
        completion: ((CachedClip?) -> Void)? = nil
    ) {
        let key = url.absoluteString
        cacheLock.lock()
        if let existing = clipCache[key] {
            cacheLock.unlock()
            DispatchQueue.main.async { completion?(existing) }
            return
        }
        if bakingKeys.contains(key) {
            cacheLock.unlock()
            // Another bake in flight — poll briefly for callers that need the result.
            if let completion {
                DispatchQueue.global(qos: .userInitiated).async {
                    for _ in 0..<200 {
                        Thread.sleep(forTimeInterval: 0.05)
                        cacheLock.lock()
                        let clip = clipCache[key]
                        let stillBaking = bakingKeys.contains(key)
                        cacheLock.unlock()
                        if let clip {
                            DispatchQueue.main.async { completion(clip) }
                            return
                        }
                        if !stillBaking { break }
                    }
                    DispatchQueue.main.async { completion(nil) }
                }
            }
            return
        }
        bakingKeys.insert(key)
        cacheLock.unlock()

        DispatchQueue.global(qos: .userInitiated).async {
            let baked = bakeClip(url: url, maxBakeDimension: maxBakeDimension, similarity: similarity, blend: blend)
            DispatchQueue.main.async {
                var clip: CachedClip?
                if let baked {
                    let textures = baked.images.map { cg -> SKTexture in
                        let t = SKTexture(cgImage: cg)
                        t.filteringMode = .linear
                        return t
                    }
                    clip = CachedClip(textures: textures, timePerFrame: baked.timePerFrame)
                }
                cacheLock.lock()
                if let clip {
                    clipCache[key] = clip
                }
                bakingKeys.remove(key)
                cacheLock.unlock()
                completion?(clip)
            }
        }
    }

    private struct BakedFrames {
        let images: [CGImage]
        let timePerFrame: TimeInterval
    }

    /// Decode once via `AVAssetReader`, key at reduced resolution, keep upright.
    private static func bakeClip(
        url: URL,
        maxBakeDimension: Int,
        similarity: Float,
        blend: Float
    ) -> BakedFrames? {
        let asset = AVURLAsset(url: url)
        guard let track = asset.tracks(withMediaType: .video).first else { return nil }

        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            print("⚠️ ChromaKey bake reader failed: \(error)")
            return nil
        }

        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return nil }
        reader.add(output)
        guard reader.startReading() else { return nil }

        let fps = Double(track.nominalFrameRate)
        let timePerFrame = fps > 1 ? 1.0 / fps : 1.0 / 24.0

        var images: [CGImage] = []
        images.reserveCapacity(160)

        while reader.status == .reading {
            guard let sample = output.copyNextSampleBuffer(),
                  let buffer = CMSampleBufferGetImageBuffer(sample) else {
                break
            }
            if let keyed = chromaKeyImage(
                from: buffer,
                similarity: similarity,
                blend: blend,
                maxDimension: maxBakeDimension
            ) {
                images.append(keyed)
            }
        }

        guard !images.isEmpty else {
            print("⚠️ ChromaKey bake produced no frames for \(url.lastPathComponent)")
            return nil
        }
        print("✅ ChromaKey baked \(images.count) frames @≤\(maxBakeDimension)px for \(url.lastPathComponent)")
        return BakedFrames(images: images, timePerFrame: timePerFrame)
    }

    /// Keys flat `#00FF00` by RGB distance; keeps muted olive clothing.
    /// Optionally downsamples while keying (nearest) so bake cost stays small.
    static func chromaKeyImage(
        from pixelBuffer: CVPixelBuffer,
        similarity: Float,
        blend: Float,
        maxDimension: Int = .max,
        context: CIContext? = nil
    ) -> CGImage? {
        _ = context // retained in signature for call-site compatibility
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let scale = min(1.0, CGFloat(maxDimension) / CGFloat(max(width, height)))
        let outW = max(1, Int((CGFloat(width) * scale).rounded(.down)))
        let outH = max(1, Int((CGFloat(height) * scale).rounded(.down)))

        // Output upright premultiplied RGBA.
        var out = [UInt8](repeating: 0, count: outW * outH * 4)
        let keyR: Float = 0
        let keyG: Float = 255
        let keyB: Float = 0
        let inv255: Float = 1.0 / 255.0
        let softLo = similarity - blend
        let softRange = max(2 * blend, 0.0001)

        for y in 0..<outH {
            // AVAssetReader / AVPlayerItemVideoOutput BGRA buffers are top-down here;
            // do not vertically flip (that inverted every clip).
            let srcY = min(height - 1, y * height / outH)
            let srcRow = base.advanced(by: srcY * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in 0..<outW {
                let srcX = min(width - 1, x * width / outW)
                let i = srcX * 4
                let b = Float(srcRow[i + 0])
                let g = Float(srcRow[i + 1])
                let r = Float(srcRow[i + 2])

                let dr = (r - keyR) * inv255
                let dg = (g - keyG) * inv255
                let db = (b - keyB) * inv255
                let dist = sqrt(dr * dr + dg * dg + db * db)

                // alpha 0 near key color, 1 when far (vest/skin/hair).
                var alpha = (dist - softLo) / softRange
                if alpha < 0 { alpha = 0 }
                if alpha > 1 { alpha = 1 }

                let maxRB = max(r, b)
                var outG = g
                // Light green despill on partially keyed fringe only.
                if alpha < 0.95 && g > maxRB {
                    let despill = min(max((g - maxRB) / 90.0, 0), 1) * 0.85
                    outG = g * (1 - despill) + maxRB * despill
                }
                // Kill residual neon on almost-opaque edge pixels.
                if alpha > 0.85 && g > maxRB + 25 {
                    outG = maxRB + 12
                }

                let oi = (y * outW + x) * 4
                let a = alpha
                out[oi + 0] = UInt8(max(0, min(255, r * a)))
                out[oi + 1] = UInt8(max(0, min(255, outG * a)))
                out[oi + 2] = UInt8(max(0, min(255, b * a)))
                out[oi + 3] = UInt8(max(0, min(255, a * 255)))
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let ctx = CGContext(
            data: &out,
            width: outW,
            height: outH,
            bitsPerComponent: 8,
            bytesPerRow: outW * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        return ctx.makeImage()
    }
}
