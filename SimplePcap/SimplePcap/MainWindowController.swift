//
//  MainWindowController.swift
//  SimplePcap
//
//  Created by Yamin Tian on 6/8/20.
//  Copyright © 2020 Demo. All rights reserved.
//

import Cocoa
import SystemExtensions
import NetworkExtension
import os.log

class MainWindowController: NSWindowController {

    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var startButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    
    enum Status {
        case stopped
        case indeterminate
        case running
    }
    
    var status: Status = .stopped {
        didSet {
            // Update the UI to reflect the new status
            switch status {
                case .stopped:
                    stopButton.isHidden = true
                    startButton.isHidden = false
                case .indeterminate:
                    stopButton.isHidden = true
                    startButton.isHidden = true
                case .running:
                    stopButton.isHidden = false
                    startButton.isHidden = true
            }
        }
    }
    
    lazy var extensionBundle: Bundle = {

        let extensionsDirectoryURL = URL(fileURLWithPath: "Contents/Library/SystemExtensions", relativeTo: Bundle.main.bundleURL)
        let extensionURLs: [URL]
        do {
            extensionURLs = try FileManager.default.contentsOfDirectory(at: extensionsDirectoryURL,
                                                                        includingPropertiesForKeys: nil,
                                                                        options: .skipsHiddenFiles)
        } catch let error {
            fatalError("Failed to get the contents of \(extensionsDirectoryURL.absoluteString): \(error.localizedDescription)")
        }

        guard let extensionURL = extensionURLs.first else {
            fatalError("Failed to find any system extensions")
        }

        guard let extensionBundle = Bundle(url: extensionURL) else {
            fatalError("Failed to create a bundle with URL \(extensionURL.absoluteString)")
        }

        return extensionBundle
    }()

    override var windowNibName: String? {
        return "MainWindowController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        status = .stopped
    }
    
    // UI events handler
    @IBAction func startFilter(sender: AnyObject) {
        // Tell the text field what to display
        status = .indeterminate
        textField.stringValue = "Start button clicked"
        
        guard let extensionIdentifier = extensionBundle.bundleIdentifier else {
            self.status = .stopped
            return
        }

        // Start by activating the system extension
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extensionIdentifier, queue: .main)
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)
    }
    
    @IBAction func stopFilter(sender: AnyObject) {
        // Tell the text field what to display
        textField.stringValue = "Stop button clicked"
        status = .indeterminate
        
        let filterManager = NEFilterManager.shared()

        guard filterManager.isEnabled else {
            status = .stopped
            return
        }

        loadFilterConfiguration { success in
            guard success else {
                self.status = .running
                return
            }

            // Disable the content filter configuration
            filterManager.isEnabled = false
            filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("Failed to disable the filter configuration: %@", error.localizedDescription)
                        self.status = .running
                        return
                    }

                    self.status = .stopped
                }
            }
        }
    }
    
    // Content Filter Configuration Management

    func loadFilterConfiguration(completionHandler: @escaping (Bool) -> Void) {

        NEFilterManager.shared().loadFromPreferences { loadError in
            DispatchQueue.main.async {
                var success = true
                if let error = loadError {
                    os_log("Failed to load the filter configuration: %@", error.localizedDescription)
                    success = false
                }
                completionHandler(success)
            }
        }
    }
    
    func enableFilterConfiguration() {

        let filterManager = NEFilterManager.shared()

        guard !filterManager.isEnabled else {
            //registerWithProvider()
            return
        }

        loadFilterConfiguration { success in

            guard success else {
                self.status = .stopped
                return
            }

            if filterManager.providerConfiguration == nil {
                let providerConfiguration = NEFilterProviderConfiguration()
                providerConfiguration.filterSockets = false
                providerConfiguration.filterPackets = true
                filterManager.providerConfiguration = providerConfiguration
                if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                    filterManager.localizedDescription = appName
                }
            }
            os_log("AAAAAAAAAAA")

            filterManager.isEnabled = true

            filterManager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    if let error = saveError {
                        os_log("Failed to save the filter configuration: %@", error.localizedDescription)
                        self.status = .stopped
                        return
                    }
                    os_log("BBBBBBBBBBB")
                    //self.registerWithProvider()
                }
            }
            self.status = .running
        }
    }
    
}

extension MainWindowController: OSSystemExtensionRequestDelegate {

    // MARK: OSSystemExtensionActivationRequestDelegate

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {

        guard result == .completed else {
            os_log("Unexpected result %d for system extension request", result.rawValue)
            status = .stopped
            return
        }

        enableFilterConfiguration()
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {

        os_log("System extension request failed: %@", error.localizedDescription)
        status = .stopped

    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {

        os_log("Extension %@ requires user approval", request.identifier)
    }

    func request(_ request: OSSystemExtensionRequest,
                 actionForReplacingExtension existing: OSSystemExtensionProperties,
                 withExtension extension: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {

        os_log("Replacing extension %@ version %@ with version %@", request.identifier, existing.bundleShortVersion, `extension`.bundleShortVersion)
        return .replace
    }
}

