/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    manager.requestAlwaysAuthorization()
    return manager
  }()
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    requestNotificationPermissions()
    return true
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    application.applicationIconBadgeNumber = 0
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  }

  private func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (result, error) in
      if let error = error {
        assertionFailure(error.localizedDescription)
      }
    }
  }
  
}


extension AppDelegate: CLLocationManagerDelegate {

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    switch region {
    case is CLCircularRegion:
      handleEvent(for: region)
      
    default:
      break
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    switch region {
    case is CLCircularRegion:
      handleEvent(for: region)
      
    default:
      break
    }
  }

  // MARK: - Private methods

  private func handleEvent(for region: CLRegion?) {
    guard let region = region else {
      assertionFailure("Region should not be nil")
      return
    }
    
    guard UIApplication.shared.applicationState == .active else {
      notify(for: region)
      return
    }
    
    let message = note(from: region.identifier)
    window?.rootViewController?.showAlert(withTitle: nil, message: message)
  }
  
  private func notify(for region: CLRegion) {
    guard let body = note(from: region.identifier) else { return }

    let request = makeNotificationRequest(with: body)
    UNUserNotificationCenter.current().add(request) { (error) in
      if let error = error { assertionFailure(error.localizedDescription) }
    }
  }
  
  private func makeNotificationRequest(with body: String) -> UNNotificationRequest {
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: "locationChange",
                                        content: makeNotificationContent(with: body),
                                        trigger: trigger)
    
    return request
  }
  
  private func makeNotificationContent(with body: String) -> UNNotificationContent {
    let notificationContent = UNMutableNotificationContent()
    notificationContent.body = body
    notificationContent.sound = .default()
    
    let badgesCount = (UIApplication.shared.applicationIconBadgeNumber + 1) as NSNumber
    notificationContent.badge = badgesCount
    
    return notificationContent
  }
  
  private func note(from identifier: String) -> String? {
    let geotifications = Geotification.allGeotifications()
    let matched = geotifications.filter({ $0.identifier == identifier }).first
    return matched?.note
  }
  
}
