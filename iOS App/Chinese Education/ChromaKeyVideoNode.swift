import SpriteKit
import AVFoundation
import CoreImage
import UIKit

/// Plays an H.264 (or similar) clip on an `SKSpriteNode` while discarding flat chroma green.
///
/// Plain `SKVideoNode` + H.264 cannot store or composite alpha, so green-screen character
/// clips would show as neon rectangles. This node pulls frames via `AVPlayerItemVideoOutput`
/// and applies an SKShader tuned like ffmpeg `chromakey=0x00FF00:0.18:0.08` plus a light
/// green despill, so SpriteKit actually draws transparent pixels.
final class ChromaKeyVideoNode: SKSpriteNode {
    private(set) var player: AVPlayer
    private var videoOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    private var endObserver: NSObjectProtocol?
    private let loops: Bool
    private let ciContext = CIContext()

    /// Shader approximates ffmpeg chromakey similarity 0.18 / blend 0.08 + green despill.
    private static let chromaKeyShader: SKShader = {
        let source = """
        void main() {
            vec4 c = texture2D(u_texture, v_tex_coord);
            float maxRB = max(c.r, c.b);
            float greenExcess = c.g - maxRB;
            // Soft key window matching similarity≈0.18, blend≈0.08
            float key = smoothstep(0.08, 0.26, greenExcess);
            // Light green despill on fringes (keeps olive vest / skin)
            float despillAmt = clamp(greenExcess / 0.18, 0.0, 1.0) * 0.55;
            c.g = mix(c.g, maxRB, despillAmt);
            c.a *= (1.0 - key);
            c.rgb *= c.a;
            gl_FragColor = c;
        }
        """
        return SKShader(source: source)
    }()

    init(url: URL, size: CGSize, loops: Bool = true, muted: Bool = true) {
        self.loops = loops
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.volume = muted ? 0 : 1
        player.actionAtItemEnd = loops ? .none : .pause
        self.player = player

        super.init(texture: nil, color: .clear, size: size)
        blendMode = .alpha
        shader = Self.chromaKeyShader
        name = "chromaKeyVideo"

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

        var image = CIImage(cvPixelBuffer: buffer)
        // AVFoundation buffers are often bottom-up relative to SpriteKit textures.
        let height = image.extent.height
        image = image.transformed(by: CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: height))

        let extent = image.extent.integral
        guard extent.width > 1, extent.height > 1,
              let cgImage = ciContext.createCGImage(image, from: extent) else {
            return
        }

        let newTexture = SKTexture(cgImage: cgImage)
        newTexture.filteringMode = .linear
        texture = newTexture
    }
}
