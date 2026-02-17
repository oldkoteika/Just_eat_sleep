import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let appDelegate = UIApplication.shared.delegate as! FlutterAppDelegate
    let flutterViewController = FlutterViewController(
      engine: appDelegate.engine,
      nibName: nil,
      bundle: nil
    )

    window = UIWindow(windowScene: windowScene)
    window?.rootViewController = flutterViewController
    window?.makeKeyAndVisible()
  }
}
