//
//  UpdateHandler.swift
//  Project Altis
//
//  Created by Hunter Ray on 2/8/17.
//  Copyright © 2017 Judge2020. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class updateHandler {
    //new stuff goes here until I can move everything over
    func checkGithub() -> Bool{
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if (version == nil){
            print("Could not get current version number")
            return false
        }
        var isUpdate = "false"
        print("Current program version: " + version!)
        Alamofire.request("https://api.github.com/repos/judge2020/AltisLauncher-Mac/releases/latest").responseString{response in
            let raw = response.result.value!
            let json = JSON(data: raw.data(using: .utf8)!)
            let latest = json["tag_name"].stringValue
            print("Current Tag: " + latest)
            if (version! < latest){
                isUpdate = "true"
            }
        }
        if (isUpdate == "true"){
            return true
        }
        return false
    }
}
