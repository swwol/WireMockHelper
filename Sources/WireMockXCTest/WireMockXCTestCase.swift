import Foundation
import XCTest

open class WireMockXCTestCase: XCTestCase {

  enum Error: Swift.Error {
    case noConfigFile
  }

  public var app: XCUIApplication!
  public var wireMocks: [WireMock] = []
  public var hostMock: WireMock!

  public override func setUp() {
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
  }
}

