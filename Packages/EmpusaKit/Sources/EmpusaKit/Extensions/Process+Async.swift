import Foundation

extension Process {

    func launch() async {
        await withCheckedContinuation { continuation in
            terminationHandler = { _ in
                continuation.resume()
            }

            launch()
        }
    }

}
