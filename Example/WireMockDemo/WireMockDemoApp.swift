import SwiftUI
import WireMockHelper

@main
struct WireMockDemoApp: App {
  @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
          ContentView(api: api)
        }
    }
  var api: APIClient {
    APIClient()
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {

    BaseURLSwapperURLProtocol.enable()
    return true
  }
}
