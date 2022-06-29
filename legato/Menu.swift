import Cocoa
import SwiftUI

class MainMenu: NSObject {
  let menu = NSMenu()
  
  func build(lights: [Light]) -> NSMenu {
    menu.autoenablesItems = false
    
    lights.forEach { light in
      let lightItem = NSMenuItem()
      lightItem.title = light.name
      lightItem.state = light.selected ? .on : .off
      lightItem.isEnabled = true
      menu.addItem(lightItem)
    }
    
    menu.addItem(NSMenuItem.separator())
    
    let quitMenuItem = NSMenuItem(
      title: "Quit Ragnar",
      action: #selector(quit),
      keyEquivalent: "q"
    )
    
    quitMenuItem.target = self
    menu.addItem(quitMenuItem)
    return menu
  }

  @objc func quit(sender: NSMenuItem) {
    NSApp.terminate(self)
  }
}
