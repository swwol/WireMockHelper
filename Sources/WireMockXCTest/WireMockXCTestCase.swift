import Foundation
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
    guard let configDataUrl = Bundle(for: type(of: self)).url(forResource: "wiremock_config", withExtension: "json"),
    let configHostURL = Bundle(for: type(of: self)).url(forResource: "wiremock_host", withExtension: "txt") else {
      XCTFail("Could not find wiremock config files in test bundle")
      return
    }
    let address: String
    do {
      let data = try Data(contentsOf: configDataUrl)
      self.wireMocks = try JSONDecoder().decode([WireMock].self, from: data)
      address = try String(contentsOf: configHostURL).trimmingCharacters(in: .whitespacesAndNewlines)
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
    app.launchEnvironment["CONFIG_BASE_URL"] = "http://\(address):8080"
    continueAfterFailure = false
  }
}

