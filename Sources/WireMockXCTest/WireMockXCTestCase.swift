import Foundation
import FlyingFox
import XCTest

open class WireMockXCTestCase: XCTestCase {

  enum Error: Swift.Error {
    case noConfigFile
  }

  public var app: XCUIApplication!
  public var wireMocks: [WireMock] = []
  public var hostMock: WireMock!

  open override func setUp() {
    super.setUp()
    guard let url = Bundle(for: type(of: self)).url(forResource: "wiremock_config", withExtension: "json") else {
      XCTFail("Could not find wiremock_config.json in test bundle")
      return
    }
    do {
      let data = try Data(contentsOf: url)
      self.wireMocks = try JSONDecoder().decode([WireMock].self, from: data)
    } catch {
      XCTFail("Failed to decode mock config: \(error)")
      return
    }
    guard let hostMock = wireMocks.first(where: { $0.configOverride != nil }) else {
      XCTFail("No WireMock defined hosting config")
      return
    }
    self.hostMock = hostMock
    self.app = XCUIApplication()
    app.launchEnvironment["CONFIG_BASE_URL"] = "http://localhost:\(hostMock.port)"
    continueAfterFailure = false

    addTeardownBlock {
      Task {
        await self.stopServers()
      }
    }
  }

  public func configureServers() async {
    await hostMock.server.appendRoute("/ios/production/msconfig-v2.json") { request in
      return HTTPResponse.init(statusCode: .ok, body: "hello".data(using: .utf8)!)
    }
  }


  public func startServers() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
      for wireMock in wireMocks {
        group.addTask {
          try await wireMock.start()
        }
      }
      try await group.waitForAll()
    }
  }

  public func stopServers() async {
    await withTaskGroup(of: Void.self) { group in
      for wireMock in wireMocks {
        group.addTask {
          await wireMock.stop()
        }
      }
      await group.waitForAll()
    }
  }
}

extension WireMock {
  var server: HTTPServer {
    HTTPServer(port: UInt16(port))
  }
  func start() async throws {
    try await server.run()
    print("started \(name)")
  }

  func stop() async {
    await server.stop()
  }
}
