import WireMockXCTest
import XCTest

final class WireMockDemoUITests: WireMockXCTestCase {

  override func setUp() {
    super.setUp(mode: .playback)
  }

  func test_example_oneCallToOneEndpoint_usingClosureSyntax() {
    app.buttons["Fetch Apple (Closure)"].firstMatch.tap()
    XCTAssert(app.staticTexts["Apple"].waitForExistence(timeout: 5))
  }

  func test_example_variantToOneEndpoint_usingClosureSyntax() {
    app.buttons["Fetch Apple (Closure)"].firstMatch.tap()
    XCTAssert(app.staticTexts["Banana"].waitForExistence(timeout: 5))
    print("ddd")
  }
}
