import SwiftUI
import Network

@main
struct legatoApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      VStack {}
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  static private(set) var instance: AppDelegate!

  lazy var statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  let menu = MainMenu()
  var tracker: LightTracker?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    AppDelegate.instance = self
    self.tracker = LightTracker()
    tracker!.start()
    statusBarItem.button?.image = NSImage(named: NSImage.Name("menubar"))
    statusBarItem.button?.image!.size.width = 24
    statusBarItem.button?.image!.size.height = 24
    statusBarItem.button?.imagePosition = .imageLeading
    statusBarItem.menu = menu.build(lights: tracker!.lights)
  }
}
