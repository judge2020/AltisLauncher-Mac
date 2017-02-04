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

class ViewController: NSViewController {
    
    @IBOutlet weak var _StatusField: NSTextField!
    @IBOutlet weak var _UsermameField: NSTextField!
    @IBOutlet weak var _PasswordField: NSSecureTextField!
    
    let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    var dataPath: URL? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataPath = documentsDirectory.appendingPathComponent("TTPA")
        
        do {
            try FileManager.default.createDirectory(atPath: (dataPath?.path)!, withIntermediateDirectories: true, attributes: nil)
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
        Alamofire.request("https://projectaltis.com/api/manifest").responseString{response in
            var raw = response.result.value! as String
            raw = "{" + raw + "}"
            let array = raw.components(separatedBy: "#")
            
            //handle update
            for root in array{
                let json = JSON(data: root.data(using: .utf8)!)
                let filename = json["filename"].stringValue
                if (filename.isEmpty) {return}
                let filepath = (self.dataPath?.appendingPathComponent(filename).path)!
                if (!FileManager.default.fileExists(atPath: filepath)){
                    print("fff" + filename)
                }
                else{
                    print("ddd" + filename)
                } 
            }
            
            
        }
    }
    
    func sha256(_ data: Data) -> Data? {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return nil }
        CC_SHA256((data as NSData).bytes, CC_LONG(data.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
    
    func sha256s(_ str: String) -> String? {
        guard
            let data = str.data(using: String.Encoding.utf8),
            let shaData = sha256(data)
            else { return nil }
        let rc = shaData.base64EncodedString(options: [])
        return rc
    }
    

    
    func launchTT(username: String, password: String){
        setEnvironmentVar(name: "TT_USERNAME", value: username, overwrite: true)
        setEnvironmentVar(name: "TT_PASSWORD", value: password, overwrite: true)
        setEnvironmentVar(name: "TT_GAMESERVER", value: "gs1.projectaltis.com", overwrite: true)
        shell("Applications/Wine\\ Staging.app/Contents/MacOS/wine", (dataPath?.path)! + "ProjectAltis.exe")
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


extension String {
    
    func split(regex pattern: String) -> [String] {
        
        guard let re = try? NSRegularExpression(pattern: pattern, options: [])
            else { return [] }
        
        let nsString = self as NSString // needed for range compatibility
        let stop = "<SomeStringThatYouDoNotExpectToOccurInSelf>"
        let modifiedString = re.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: stop)
        return modifiedString.components(separatedBy: stop)
    }
}

