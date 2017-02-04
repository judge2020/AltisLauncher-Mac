//
//  ViewController.swift
//  Project Altis
//
//  Created by Hunter Ray on 1/31/17.
//  Copyright © 2017 Judge2020. All rights reserved.
//

import Cocoa
import Foundation
import Alamofire
import SwiftyJSON
import CryptoSwift

class ViewController: NSViewController {
    
    @IBOutlet weak var _StatusField: NSTextField!
    @IBOutlet weak var _UsermameField: NSTextField!
    @IBOutlet weak var _PasswordField: NSSecureTextField!
    
    let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    var dataPath: URL? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startup()
        
    }
    
    func startup(){
        dataPath = documentsDirectory.appendingPathComponent("TTPA")
        
        do {
            try FileManager.default.createDirectory(atPath: (dataPath?.path)!, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: (dataPath?.appendingPathComponent("config", isDirectory: true))!.path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: (dataPath?.appendingPathComponent("resources/default", isDirectory: true))!.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func PlayPress(_ sender: Any) {
        _StatusField.stringValue = "Checking for updates..."
        Alamofire.request("https://projectaltis.com/api/manifest").responseString{response in
            let raw = response.result.value! as String
            let array = raw.components(separatedBy: "#")
            
            //handle update
            self.handleUpdate(array: array)
            
            self.launchTT(username: self._UsermameField.stringValue, password: self._PasswordField.stringValue)
        }
    }
    @IBAction func RedownloadPress(_ sender: Any) {
        try? FileManager.default.removeItem(at: dataPath!)
        
        startup()
        
        _StatusField.stringValue = "Redownloading..."
        Alamofire.request("https://projectaltis.com/api/manifest").responseString{response in
            let raw = response.result.value! as String
            let array = raw.components(separatedBy: "#")
            
            //handle update
            self.handleUpdate(array: array)
        }
    }
    
    func handleUpdate(array: [String]){
        for root in array{
            let json = JSON(data: root.data(using: .utf8)!)
            var filename = json["filename"].stringValue
            if (filename.isEmpty) {return}
            
            if (filename =~ "phase_.+\\.mf"){
                filename = "resources/default/" + filename
            }
            if (filename == "toon.dc"){
                filename = "config/" + filename
            }
            
            let filepath = (self.dataPath?.appendingPathComponent(filename))!
            if (!FileManager.default.fileExists(atPath: filepath.path)){
                print("Missing: " + filename)
                _StatusField.stringValue = "Downloading files..."
                Downloader.load(url: try! json["url"].stringValue.asURL(), to: filepath, completion: ({}))
            }
            else{
                print("Found: " + filename)
            }
        }
    }
    

    
    func launchTT(username: String, password: String){
        self._StatusField.stringValue = "Note: Do NOT report bugs for this to the TTPA team!"
        self._UsermameField.stringValue = "NOTE: expect extreme performance issues."
        self._PasswordField.stringValue = ""
        setEnvironmentVar(name: "TT_USERNAME", value: username, overwrite: true)
        setEnvironmentVar(name: "TT_PASSWORD", value: password, overwrite: true)
        setEnvironmentVar(name: "TT_GAMESERVER", value: "gs1.projectaltis.com", overwrite: true)
        //shell("/Applications/Wine\\ Staging.app/Contents/MacOS/wine", (dataPath?.path)! + "/ProjectAltis.exe")
        Process.launchedProcess(launchPath: "/Applications/Wine Staging.app/Contents/MacOS/wine", arguments: [(dataPath?.path)! + "/ProjectAltis.exe"])
    }
    
    func setEnvironmentVar(name: String, value: String, overwrite: Bool) {
        setenv(name, value, overwrite ? 1 : 0)
    }
    
    @discardableResult
    func shell(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }

}

class Downloader {
    class func load(url: URL, to localUrl: URL, completion: @escaping () -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = try! URLRequest(url: url, method: .get)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                    completion()
                } catch (let writeError) {
                    print("error writing file \(localUrl) : \(writeError)")
                }
                
            } else {
                print("Failure: %@", error?.localizedDescription as Any);
            }
        }
        task.resume()
    }
}

class Regex {
    let internalExpression: NSRegularExpression
    let pattern: String
    
    init(_ pattern: String) {
        self.pattern = pattern
        self.internalExpression = try! NSRegularExpression(pattern: pattern, options: [])
    }
    
    func test(input: String) -> Bool {
        let matches = self.internalExpression.matches(in: input, options: [], range:NSRange(location: 0, length: input.characters.count))
        return matches.count > 0
    }
}

infix operator =~
func =~ (input: String, pattern: String) -> Bool {
    return Regex(pattern).test(input: input)
}
