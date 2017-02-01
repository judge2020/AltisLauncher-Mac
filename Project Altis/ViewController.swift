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

class ViewController: NSViewController {
    
    @IBOutlet weak var _StatusField: NSTextField!
    @IBOutlet weak var _UsermameField: NSTextField!
    @IBOutlet weak var _PasswordField: NSSecureTextField!

    @IBOutlet weak var infofield: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func PlayPress(_ sender: Any) {
        let data = NSData(contentsOf: URL(string: "https://projectaltis.com/api/manifest")!)
        var manifest = try? JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.mutableContainers)
        var df = try? JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.allowFragments)
    }
    
    func launchTT(username: String, password: String){
        setEnvironmentVar(name: "TT_USERNAME", value: username, overwrite: true)
        setEnvironmentVar(name: "TT_PASSWORD", value: password, overwrite: true)
        setEnvironmentVar(name: "TT_GAMESERVER", value: "gs1.projectaltis.com", overwrite: true)
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

