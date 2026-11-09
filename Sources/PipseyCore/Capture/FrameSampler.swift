import Foundation
import CoreMedia
import CoreGraphics
import CryptoKit

public struct SampledFrame: Sendable {
    public var metadata: FrameMetadata
    public var rawImageData: Data?

    public init(metadata: FrameMetadata, rawImageData: Data? = nil) {
        self.metadata = metadata
        self.rawImageData = rawImageData
    }
}

public actor FrameSampler {
    public private(set) var sampledFrames: [FrameMetadata] = []
    private var lastSampleMonotonicMs: Int64 = -1
    private let targetFps: Double
    private let maxFrames: Int
    private let minIntervalMs: Int64
    private let sessionDirectory: URL

    public init(targetFps: Double = 2.0, maxFrames: Int = 60, sessionDirectory: URL) {
        self.targetFps = targetFps
        self.maxFrames = maxFrames
        self.minIntervalMs = Int64(1000.0 / targetFps)
        self.sessionDirectory = sessionDirectory
        try? FileManager.default.createDirectory(at: sessionDirectory, withIntermediateDirectories: true)
    }

    public func sampleFrame(
        relativeTimeMs: Int64,
        width: Int,
        height: Int,
        jpegData: Data,
        forceBurst: Bool = false
    ) -> FrameMetadata? {
        guard sampledFrames.count < maxFrames else { return nil }

        if !forceBurst && lastSampleMonotonicMs >= 0 && (relativeTimeMs - lastSampleMonotonicMs) < minIntervalMs {
            return nil
        }

        lastSampleMonotonicMs = relativeTimeMs
        let frameIndex = sampledFrames.count + 1
        let frameId = String(format: "frame-%03d", frameIndex)

        // Compute SHA256 of frame pixels/JPEG
        let hash = SHA256.hash(data: jpegData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

        let fileURL = sessionDirectory.appendingPathComponent("\(frameId).jpg")
        try? jpegData.write(to: fileURL)

        let metadata = FrameMetadata(
            frameId: frameId,
            relativeTimeMs: relativeTimeMs,
            width: width,
            height: height,
            sha256: hashString,
            localRef: fileURL.path
        )
        sampledFrames.append(metadata)
        return metadata
    }

    public func cleanup() {
        try? FileManager.default.removeItem(at: sessionDirectory)
    }
}
