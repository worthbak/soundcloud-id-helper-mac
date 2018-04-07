//
//  ViewController.swift
//  SoundCloud Helper
//
//  Created by Worth Baker on 4/7/18.
//  Copyright © 2018 worthbak. All rights reserved.
//

import Cocoa

final class ViewController: NSViewController {
    
    enum State {
        case waitingForInput
        case fetchingData(url: URL)
        case error(description: String)
        case displayingResult(result: SoundCloudResult)
    }
    
    struct SoundCloudResult: Codable {
        let id: Int
    }
    
    private var currentState: State = .waitingForInput {
        didSet { updateForNewState() }
    }

    @IBOutlet weak var fetchButton: NSButton!
    @IBOutlet weak var urlTextField: NSTextField!
    @IBOutlet weak var infoTextField: NSTextField!
    @IBOutlet weak var outputTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchButton.action = #selector(fetchButtonTapped(_:))
        currentState = .waitingForInput
    }

    @objc
    func fetchButtonTapped(_ sender: Any) {
        guard URL(string: urlTextField.stringValue) != nil else {
            currentState = .error(description: "Invalid SoundCloud URL")
            return
        }
        
        guard let url = URL(string: "https://api.soundcloud.com/resolve?url=\(urlTextField.stringValue)&client_id=788bebab07b8a2a6282710fe2a80467c") else {
            currentState = .error(description: "Failed to construct request.")
            return
        }
        
        URLSession.shared.dataTask(with: url, completionHandler: { data, res, err in
            DispatchQueue.main.async {
                guard let data = data else {
                    self.currentState = .error(description: "SoundCloud Request Failed; \(err?.localizedDescription ?? "unknown")")
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(SoundCloudResult.self, from: data)
                    self.currentState = .displayingResult(result: result)
                } catch {
                    print(error)
                    self.currentState = .error(description: "Failed to parse JSON response.")
                }
            }
        }).resume()
    }
    
    private func updateForNewState() {
        switch currentState {
        case .waitingForInput:
            updateForWaitingState()
        case .fetchingData(_):
            updateForFetchingState()
        case .error(let description):
            updateForErrorState(description)
        case .displayingResult(let result):
            updateForResultState(result)
        }
    }
    
    private func updateForWaitingState() {
        urlTextField.stringValue = ""
        infoTextField.stringValue = ""
        outputTextField.stringValue = ""
    }
    
    private func updateForErrorState(_ errorText: String) {
        infoTextField.stringValue = "Encountered an error:"
        outputTextField.stringValue = errorText
    }
    
    private func updateForFetchingState() {
        infoTextField.stringValue = "Fetching ID..."
        outputTextField.stringValue = ""
    }
    
    private func updateForResultState(_ result: SoundCloudResult) {
        infoTextField.stringValue = "Found Soundcloud ID:"
        outputTextField.stringValue = String(result.id)
    }
    
}

