import AppKit
import Foundation
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list])
  }
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("brew-autoupdate notifier: \(message)\n".utf8))
  exit(1)
}

guard CommandLine.arguments.count == 4 else {
  fail("expected a title, subtitle, and message")
}

let application = NSApplication.shared
application.setActivationPolicy(.accessory)

let notificationCenter = UNUserNotificationCenter.current()
let notificationDelegate = NotificationDelegate()
notificationCenter.delegate = notificationDelegate

notificationCenter.requestAuthorization(options: [.alert]) { granted, error in
  if let error {
    fail("could not request notification permission: \(error.localizedDescription)")
  }
  guard granted else {
    fail("notifications are disabled in System Settings")
  }

  let content = UNMutableNotificationContent()
  content.title = CommandLine.arguments[1]
  content.subtitle = CommandLine.arguments[2]
  content.body = CommandLine.arguments[3]

  let request = UNNotificationRequest(
    identifier: UUID().uuidString,
    content: content,
    trigger: nil
  )
  notificationCenter.add(request) { error in
    if let error {
      fail("could not deliver notification: \(error.localizedDescription)")
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      exit(0)
    }
  }
}

RunLoop.main.run()
