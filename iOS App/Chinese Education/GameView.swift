import SwiftUI
import SpriteKit

// MARK: - 🎮 MAIN GAME VIEW - SwiftUI Container for SpriteKit Scenes
struct GameView: View {
    
    // MARK: - 🔐 AUTHENTICATION STATE
    @State private var isLoggedIn: Bool = false  // Login status tracking

    var body: some View {
        if isLoggedIn {
            // Load the GameScene once login is successful
            SpriteView(scene: GameScene.createScene())
                .ignoresSafeArea()
        } else {
            // Load SigninScene initially
            SignInContainerView(isLoggedIn: $isLoggedIn)
        }
    }
}

// MARK: - 🔐 SIGN-IN CONTAINER VIEW - Login Scene Wrapper
struct SignInContainerView: View {
    @Binding var isLoggedIn: Bool  // Binding to parent login state

    var body: some View {
        ZStack {
            // Load the SigninScene
            SpriteView(scene: SignInScene.createScene(isLoggedIn: $isLoggedIn))
                .ignoresSafeArea()
        }
    }
}

// MARK: - Scene Extensions
extension SignInScene {
    static func createScene(isLoggedIn: Binding<Bool>) -> SKScene {
        let scene = SignInScene()
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .resizeFill
        return scene
    }
}

extension GameScene {
    static func createScene() -> SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .resizeFill
        return scene
    }
}