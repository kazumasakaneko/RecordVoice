//
//  ViewController.swift
//  RecordVoice
//
//  Created by Kazumasa Kaneko on 2020/04/25.
//  Copyright © 2020 Kazumasa Kaneko. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!

    lazy var recordButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "Record", style: .plain, target: self, action: #selector(record(_:)))
        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Record Voice"
        navigationItem.rightBarButtonItem = recordButtonItem
    }

    @objc func record(_ sender: Any?) {
        guard let text = textView.text, text.count > 0 else { return }
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
        recordVoice(for: text, to: destination) { [weak self ] in
            guard let self = self else { return }
            self.export(destination)
        }
    }

    func recordVoice(for text: String, to destination: URL, completionHandler: @escaping () -> Void) {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en")
        var output: AVAudioFile?
        synthesizer.write(utterance) { buffer in
            guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                fatalError("unknown buffer type: \(buffer)")
            }
            if pcmBuffer.frameLength == 0 {
                // done
                DispatchQueue.main.async {
                    completionHandler()
                }
            } else {
                if output == nil {
                    output = try! AVAudioFile(
                        forWriting: destination,
                        settings: pcmBuffer.format.settings,
                        commonFormat: .pcmFormatInt16,
                        interleaved: false
                    )
                }
                try? output?.write(from: pcmBuffer)
            }
        }
    }

    func export(_ url: URL) {
        let viewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(viewController, animated: true, completion: nil)
    }
}

extension ViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("did finish")
    }
}
