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
final class ChromaKeyVideoNode: SKSpriteNode {
    private(set) var player: AVPlayer
    private var videoOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    private var endObserver: NSObjectProtocol?
    private let loops: Bool
    private let ciContext = CIContext(options: nil)

    /// Match tested still-frame params: screen clears, olive vest/pants stay opaque.
    private let keySimilarity: Float = 0.32
    private let keyBlend: Float = 0.10

    init(url: URL, size: CGSize, loops: Bool = true, muted: Bool = true) {
        self.loops = loops
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.volume = muted ? 0 : 1
        player.actionAtItemEnd = loops ? .none : .pause
        self.player = player

        super.init(texture: nil, color: .clear, size: size)
        blendMode = .alpha
        name = "chromaKeyVideo"
        // No SKShader — alpha is baked into each uploaded frame.

        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: outputSettings)
        item.add(output)
        videoOutput = output

        if loops {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.player.seek(to: .zero)
                self?.player.play()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stop()
    }

    func play() {
        startDisplayLinkIfNeeded()
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
        stopDisplayLink()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    override func removeFromParent() {
        stop()
        super.removeFromParent()
    }

    // MARK: - Private

    private func startDisplayLinkIfNeeded() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkFired(_ link: CADisplayLink) {
        guard let videoOutput else { return }
        let time = player.currentTime()
        guard videoOutput.hasNewPixelBuffer(forItemTime: time) else { return }
        var displayTime = CMTime.zero
        guard let buffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: &displayTime) else {
            return
        }

        guard let keyedImage = Self.chromaKeyImage(
            from: buffer,
            similarity: keySimilarity,
            blend: keyBlend,
            context: ciContext
        ) else {
            return
        }

        let newTexture = SKTexture(cgImage: keyedImage)
        newTexture.filteringMode = .linear
        texture = newTexture
    }

    /// Keys flat `#00FF00` by RGB distance; keeps muted olive clothing.
    static func chromaKeyImage(
        from pixelBuffer: CVPixelBuffer,
        similarity: Float,
        blend: Float,
        context: CIContext
    ) -> CGImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        // Output upright premultiplied RGBA.
        var out = [UInt8](repeating: 0, count: width * height * 4)
        let keyR: Float = 0
        let keyG: Float = 255
        let keyB: Float = 0
        let inv255: Float = 1.0 / 255.0
        let softLo = similarity - blend
        let softRange = max(2 * blend, 0.0001)

        for y in 0..<height {
            // AVFoundation BGRA buffers are commonly bottom-up relative to UI images.
            let srcY = height - 1 - y
            let srcRow = base.advanced(by: srcY * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in 0..<width {
                let i = x * 4
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

                let oi = (y * width + x) * 4
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
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        return ctx.makeImage()
    }
}
