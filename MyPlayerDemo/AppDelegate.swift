//
//  AppDelegate.swift
//  HiRadio
//
//  Created by samuel on 2022/1/6.
//

import Foundation
import SwiftUI


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.beginReceivingRemoteControlEvents()
        return true
    }
}
