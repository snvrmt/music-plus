// Reads an audio file with Apple's AVFoundation (same as the iPhone player)
// and checks it decodes from start to end.
import AVFoundation
import Foundation

let path = CommandLine.arguments[1]
let asset = AVURLAsset(url: URL(fileURLWithPath: path))
let sema = DispatchSemaphore(value: 0)
var ok = true
Task {
  do {
    let duration = try await asset.load(.duration)
    let playable = try await asset.load(.isPlayable)
    let tracks = try await asset.loadTracks(withMediaType: .audio)
    guard let track = tracks.first else { print("\(path): NO AUDIO TRACK"); ok = false; sema.signal(); return }
    let reader = try AVAssetReader(asset: asset)
    let out = AVAssetReaderTrackOutput(track: track, outputSettings: [AVFormatIDKey: kAudioFormatLinearPCM])
    reader.add(out)
    reader.startReading()
    var frames = 0
    while let buf = out.copyNextSampleBuffer() { frames += CMSampleBufferGetNumSamples(buf) }
    let decoded = Double(frames) / 44100.0
    print("\(path): playable=\(playable) duration=\(duration.seconds)s decoded=\(decoded)s status=\(reader.status.rawValue)")
    if !playable || reader.status != .completed || abs(decoded - duration.seconds) > 1 { ok = false }
  } catch { print("\(path): ERROR \(error)"); ok = false }
  sema.signal()
}
sema.wait()
exit(ok ? 0 : 1)
