import Foundation
import Network

class Light: Identifiable, CustomStringConvertible {
  let endpoint: NWEndpoint
  let name: String
  let description: String
  var host: String?
  var port: Int?
  var selected: Bool = true

  init(endpoint: NWEndpoint) {
    self.endpoint = endpoint
    self.name = String(describing: endpoint)
    self.description = self.name
  }

  func onOff(isOn: Bool) {
    var request = URLRequest(url: URL(string: "http://\(self.host!):\(self.port!)/elgato/lights")!)
    request.httpMethod = "put"

    let json: [String: Any] = [
      "numberOfLights": "1",
      "lights": [["on": isOn ? 1 : 0, "brightness": 40, "temperature": 500]],
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: json)
    let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in }
    task.resume()
  }

  func on() {
    onOff(isOn: true)
  }

  func off() {
    onOff(isOn: false)
  }

  func getStats() {
    let params = NWParameters.tcp
    let stack = params.defaultProtocolStack.internetProtocol! as! NWProtocolIP.Options
    stack.version = .v4
    let connection = NWConnection(to: endpoint, using: params)

    connection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        if let innerEndpoint = connection.currentPath?.remoteEndpoint,
          case .hostPort(let h, let p) = innerEndpoint
        {
          let ipv4hostparts = String(describing: h).components(separatedBy: "%")
          let ipv4host = ipv4hostparts[0]

          self.host = ipv4host
          self.port = Int(p.rawValue)

          print("Light found at \(ipv4host):\(p)")
        }
      default:
        break
      }
    }
    connection.start(queue: .global())
  }
}
