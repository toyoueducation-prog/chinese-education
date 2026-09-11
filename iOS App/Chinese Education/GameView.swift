import SwiftUI
import SpriteKit

// MARK: - 🎮 MAIN GAME VIEW - SwiftUI Container for SpriteKit Scenes
struct GameView: View {
    
    // MARK: - 🔐 AUTHENTICATION STATE
    @State private var isLoggedIn: Bool = false  // Login status tracking

    var body: some View {
        if isLoggedIn {
            // Load the GameScene once login is successful
            // ✅ Background covers full screen including safe area, but UI respects safe area
            SpriteView(scene: GameScene.createScene())
                .ignoresSafeArea(.all) // Background covers everything
        } else {
            // Load SigninScene initially
            SignInContainerView(isLoggedIn: $isLoggedIn)
                .ignoresSafeArea(.all) // Background covers everything
        }
    }
}

// MARK: - 🔐 SIGN-IN CONTAINER VIEW - Login Scene Wrapper
struct SignInContainerView: View {
    @Binding var isLoggedIn: Bool  // Binding to parent login state
    @State private var showTeacherDashboard: Bool = false  // ✅ Track teacher dashboard state
    @State private var signInScene: SignInScene?  // ✅ Store scene to prevent recreation
    @State private var teacherDashboardScene: TeacherDashboardScene?  // ✅ Store teacher scene

    var body: some View {
        ZStack {
            if showTeacherDashboard {
                // ✅ Show teacher dashboard scene
                if teacherDashboardScene == nil {
                    Color.clear
                        .onAppear {
                            let scene = TeacherDashboardScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
                            scene.scaleMode = .resizeFill
                            teacherDashboardScene = scene
                        }
                } else if let scene = teacherDashboardScene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }
            } else {
                // ✅ Create SignInScene only once
                if signInScene == nil {
                    Color.clear
                        .onAppear {
                            let scene = SignInScene.createScene(isLoggedIn: $isLoggedIn) as? SignInScene
                            signInScene = scene
                        }
                } else if let scene = signInScene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowTeacherDashboard"))) { _ in
            showTeacherDashboard = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HideTeacherDashboard"))) { _ in
            showTeacherDashboard = false
            teacherDashboardScene = nil  // Reset to allow recreation if needed
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
        // ✅ Full screen size - background covers safe area, UI elements will respect safe area
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .resizeFill
        return scene
    }
}