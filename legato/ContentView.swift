//
//  ContentView.swift
//  legato
//
//  Created by Elliott Kember on 28/06/22.
//

import SwiftUI
import Network

class ServiceAgent : NSObject, NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        if let data = sender.txtRecordData() {
            let dict = NetService.dictionary(fromTXTRecord: data)
            print("Resolved: \(dict)")
            print(dict.mapValues { String(data: $0, encoding: .utf8) })
        }
    }
}

class BrowserAgent : NSObject, NetServiceBrowserDelegate {
    var currentService:NetService?
    let serviceAgent = ServiceAgent()
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        print("domain found: \(domainString)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("service found: \(service.name)")
        self.currentService = service
        service.delegate = self.serviceAgent
        service.resolve(withTimeout: 5)
    }
}

struct ContentView: View {
    @State var tracker: LightTracker?

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }.onAppear {
            tracker = LightTracker()
            tracker!.start()
        }
    }
}

class LightTracker {
    
    var lights:[RestLight]=[]
    
    init() {
    }
    
    func start() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: .bonjour(type: "_elg._tcp", domain: nil), using: parameters)
        browser.stateUpdateHandler = { newState in
        }
        browser.browseResultsChangedHandler = { results, changes in
            for result in results {
                if case NWEndpoint.service = result.endpoint {
                    let light=RestLight(endpoint: result.endpoint)
                    self.lights.append(light)
                    light.getStats()
                }
            }
        }
        browser.start(queue: DispatchQueue.global())
        sleep(5)
        
        let task = Process()
        task.launchPath = "/usr/bin/log"
        task.arguments = ["stream"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let handle = pipe.fileHandleForReading
        handle.readInBackgroundAndNotify()
        handle.readabilityHandler = {pipe in
            guard let currentOutput = String(data: pipe.availableData, encoding: .utf8) else {
                print("Error decoding data: \(pipe.availableData)")
                return
            }
            
            guard !currentOutput.isEmpty else {
                return
            }

            print(currentOutput);
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class RestLight:Identifiable,CustomStringConvertible {
    
    let endpoint: NWEndpoint
    let name: String
    let description: String
    
    init(endpoint: NWEndpoint) {
        self.endpoint=endpoint
        self.name=String(describing:endpoint)
        self.description=self.name
    }
    
    func getStats()
    {
        let params = NWParameters.tcp
        let stack = params.defaultProtocolStack.internetProtocol! as! NWProtocolIP.Options
        stack.version = .v4
        let connection = NWConnection(to: endpoint, using: params)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = innerEndpoint {
                    let ipv4hostparts=String(describing:host).components(separatedBy:"%")
                    let ipv4host=ipv4hostparts[0]
                    
                    print("\(ipv4host):\(port)")
            }
            default:
                break
            }
        }
        connection.start(queue: .global())
    }
    
   
}
