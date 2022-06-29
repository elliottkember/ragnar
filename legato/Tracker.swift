import Foundation
import Network

class LightTracker {
  var lights: [Light] = []

  func start() {
    let parameters = NWParameters()
    parameters.includePeerToPeer = true

    let browser = NWBrowser(for: .bonjour(type: "_elg._tcp", domain: nil), using: parameters)
    
    browser.browseResultsChangedHandler = { results, changes in
      for result in results {
        if case NWEndpoint.service = result.endpoint {
          let light = Light(endpoint: result.endpoint)
          light.getStats()
          self.lights.append(light)
        }
      }
    }

    browser.start(queue: DispatchQueue.global())

    let task = Process()
    let pipe = Pipe()
    
    task.launchPath = "/usr/bin/log"
    task.arguments = ["stream"]
    task.standardOutput = pipe
    
    pipe.fileHandleForReading.readabilityHandler = { pipe in
      guard let currentOutput = String(data: pipe.availableData, encoding: .utf8) else { return }
      guard !currentOutput.isEmpty else { return }
      guard currentOutput.contains("com.apple.UVCExtension:provider") else { return }

      if (currentOutput).contains("clientConnect") {
        for light in self.lights { light.on() }
      }

      if (currentOutput).contains("clientDisconnect") {
        for light in self.lights { light.off() }
      }
    }

    pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    task.launch()
  }
}

