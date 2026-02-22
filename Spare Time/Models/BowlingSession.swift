import Combine

class BowlingSession: ObservableObject {
    @Published var frames: [Frame] = (1...10).map { Frame(id: $0) }
    @Published var currentFrameIndex: Int = 0

    var currentFrame: Frame { frames[currentFrameIndex] }

    func updateFrame(_ frame: Frame) {
        frames[frame.id - 1] = frame
    }

    func advanceFrame() {
        guard currentFrameIndex < 9 else { return }
        currentFrameIndex += 1
    }
}
