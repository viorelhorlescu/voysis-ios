import UIKit
import Voysis
import AVFoundation

class ViewController: UIViewController {

    private let config = Config(url: URL(string: "ws://INSERT_URL/websocketapi")!, refreshToken: "INSERT_TOKEN")
    private lazy var voysis = Voysis.ServiceProvider<CommerceContext, CommerceEntities>.make(config: config)
    private var context: CommerceContext?

    @IBOutlet weak var response: UITextView!

    override func viewWillDisappear(_ animated: Bool) {
        voysis.cancel()
    }

    @IBAction func buttonClicked(_ sender: Any) {
        switch voysis.state {
        case .idle:
            voysis.startAudioQuery(context: self.context, eventHandler: handleEvent, errorHandler: handleError)
        case .busy:
            voysis.cancel()
        }
    }

    func handleEvent(event: Event) {
        switch event.type {
        case .recordingStarted:
            print("Recording Started")
        case .audioQueryCreated:
            onQueryResponse(event: event)
        case .recordingFinished:
            print("Recording Finished")
        case .vadReceived:
            print("Vad Received")
        case .audioQueryCompleted:
            onResponse(event: event)
        case .requestCancelled:
            print("Cancelled")
        }
    }

    func handleError(error: Error) {
        self.response.text = error.localizedDescription
    }

    private func onQueryResponse(event: Event) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let response = event.response! as? QueryResponse {
            if let data = try? encoder.encode(response),
               let json = String(data: data, encoding: .utf8) {
                self.response.text = json
            }
        }
    }

    private func onResponse(event: Event) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let response = event.response! as? StreamResponse<CommerceContext, CommerceEntities> {
            if let context = response.context {
                self.context = context
            }
            if let data = try? encoder.encode(response),
               let json = String(data: data, encoding: .utf8) {
                self.response.text.append("\n\n\n \(json)")
            }
        }
    }
}
