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

class ViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var _GameVersionField: NSTextField!
    @IBOutlet weak var _StatusField: NSTextField!
    @IBOutlet weak var _UsermameField: NSTextField!
    @IBOutlet weak var _PasswordField: NSSecureTextField!
    
    let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    var dataPath: URL? = nil
    
    var total = 0
    var done = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //try to create directories
        startup()
        
    }
    
    @IBAction func _PasswordFieldEnter(_ sender: Any) {
        if (!_PasswordField.stringValue.isEmpty && !_UsermameField.stringValue.isEmpty){
            PlayPress("")
        }
    }
    
    
    func startup(){
        dataPath = documentsDirectory.appendingPathComponent("TTPA")
        
        //create folders (if they don't exist)
        do {
            try FileManager.default.createDirectory(atPath: (dataPath?.path)!, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: (dataPath?.appendingPathComponent("config", isDirectory: true))!.path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: (dataPath?.appendingPathComponent("resources/default", isDirectory: true))!.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        } catch {
            print("other error")
        }

        //get game version
        Alamofire.request("http://gs1.projectaltis.com/API/Version").responseString{response in
            let raw = response.result.value! as String
            print("Game version: " + raw)
            self._GameVersionField.stringValue = "Game version: " + raw
        }
        
        //set usernamefield as first responder
        self._UsermameField.becomeFirstResponder()
        
        //reset fields
        self._UsermameField.stringValue = ""
        self._PasswordField.stringValue = ""
        self._StatusField.stringValue = "Unofficial Project Altis Mac Launcher (ALPHA)"
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func PlayPress(_ sender: Any) {
        Alamofire.request("https://projectaltis.com/api/manifest").responseString{response in
            let raw = response.result.value! as String
            let array = raw.components(separatedBy: "#")
            
            //handle update
            self.handleUpdate(array: array)
            
        }
    }
    @IBAction func RedownloadPress(_ sender: Any) {
        try? FileManager.default.removeItem(at: dataPath!)
        
        startup()
        Alamofire.request("https://projectaltis.com/api/manifest").responseString{response in
            let raw = response.result.value! as String
            let array = raw.components(separatedBy: "#")
            
            //handle update
            self.handleUpdate(array: array)
        }
    }
    
    func handleUpdate(array: [String]){
        try? FileManager.default.removeItem(at: (dataPath?.appendingPathComponent("cgGL.dll"))!)
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
                self.total += 1
                DispatchQueue.global(qos: .default).async {
                    self.downloadAlamo(path: filepath, url: json["url"].stringValue)
                }
            }
            else{
                print("Found: " + filename)
                
                //filesize checking for updates
                let filesize = (try? FileManager.default.attributesOfItem(atPath: filepath.path) as NSDictionary)?.fileSize()
                if (String(describing: filesize!) != json["size"].string){
                    print("Filesize mismatch, redownloading: " + filename)
                    self.total += 1
                    DispatchQueue.global(qos: .default).async {
                        try? FileManager.default.removeItem(at: filepath)
                        self.downloadAlamo(path: filepath, url: json["url"].stringValue)
                    }
                }
                
            }
        }
        
    }
    

    
    func launchTT(username: String, password: String){
        
        //update readable values in UI. Unofficial launcher so don't want them to get questions regarding this.
        self._StatusField.stringValue = "Note: Do NOT report bugs for this to the TTPA team!"
        self._UsermameField.stringValue = "NOTE: expect extreme performance issues."
        
        //clear password field
        self._PasswordField.stringValue = ""
        
        //set environment variables, which is what's used to login and point to the correct gameserver.
        setEnvironmentVar(name: "TT_USERNAME", value: username, overwrite: true)
        setEnvironmentVar(name: "TT_PASSWORD", value: password, overwrite: true)
        setEnvironmentVar(name: "TT_GAMESERVER", value: "gs1.projectaltis.com", overwrite: true)
        
        //start wine.
        Process.launchedProcess(launchPath: "/Applications/Wine Staging.app/Contents/MacOS/wine", arguments: [(dataPath?.path)! + "/ProjectAltis.exe"])
    }
    
    func setEnvironmentVar(name: String, value: String, overwrite: Bool) {
        setenv(name, value, overwrite ? 1 : 0)
    }
    
    func downloadAlamo(path: URL, url: String){
        //let destination = DownloadRequest.suggestedDownloadDestination(for: .applicationSupportDirectory)
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = path
            
            return (documentsURL, [.removePreviousFile])
        }
        Alamofire.download(
            url,
            method: .get,
            to: destination).downloadProgress(closure: { (progress) in
                //progress closure
            }).response(completionHandler: { (DefaultDownloadResponse) in
                self.done += 1
                self.updateStatus()
            })
    }
    
    func updateStatus(){
        if (self.done == self.total){
            self._StatusField.stringValue = "finished downloading!"
            self.launchTT(username: self._UsermameField.stringValue, password: self._PasswordField.stringValue)
            return
        }
        self._StatusField.stringValue = "Downloading... " + String(self.done) + "/" + String(self.total)
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
