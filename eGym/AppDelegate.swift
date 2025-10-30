// AppDelegate.swift
import UIKit
import FirebaseCore
import GoogleSignIn
import os

let log = Logger(subsystem: "com.egym.app", category: "auth")

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

    FirebaseApp.configure()
    FirebaseConfiguration.shared.setLoggerLevel(.debug)   // verbose Firebase logs

    // Configure Google clientID
    let firebaseClientID = FirebaseApp.app()?.options.clientID
    if let cid = firebaseClientID {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: cid)
      log.info("Configured GID with Firebase clientID: \(cid, privacy: .public)")
    } else {
      log.error("Firebase options.clientID is nil. Check GoogleService-Info.plist")
    }
    return true
  }
}
