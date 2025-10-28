import SpriteKit
import SwiftUI
import AuthenticationServices

// MARK: - 🔐 SIGN-IN SCENE - User Authentication & Login System
class SignInScene: SKScene, UITextFieldDelegate {
    
    // MARK: - 🍎 APPLE SIGN-IN COMPONENTS
    private var signInButton: ASAuthorizationAppleIDButton!  // Apple ID sign-in button
    
    // MARK: - 🎮 MANUAL LOGIN COMPONENTS
    private var manualSignInButton: SKLabelNode!            // "開始遊戲" button
    private var signInButtonBackground: SKShapeNode!        // Button background
    private var resetButton: SKLabelNode!                   // "重新開始" button
    private var resetButtonBackground: SKShapeNode!         // Reset button background
    
    // MARK: - 📝 TEXT INPUT FIELDS
    private var usernameTextField: UITextField!             // Username input field
    private var passwordTextField: UITextField!             // Password input field
    
    // MARK: - 💾 USER CREDENTIALS
    private var enteredUsername: String = ""                // Stored username
    private var enteredPassword: String = ""                // Stored password
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupGameTitle()  // ✅ Add Game Title
        setupManualSignIn()
    }
    
    override func willMove(from view: SKView) {
        // Clean up text fields when leaving the scene
        usernameTextField?.removeFromSuperview()
        passwordTextField?.removeFromSuperview()
    }
    
    // MARK: - Add Game Title
    func setupGameTitle() {
        let gameTitle = SKLabelNode(text: "讀力大冒險")
        gameTitle.fontSize = 48  // ✅ Larger font
        gameTitle.fontColor = .white
        gameTitle.fontName = "AvenirNext-Bold"
        gameTitle.position = CGPoint(x: size.width / 2, y: size.height - 150)  // ✅ Top center
        addChild(gameTitle)
    }
    
    
    // MARK: - Set Background Image
    func setupBackground() {
        let background = SKSpriteNode(imageNamed: "Morning_Forest_Background")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = size
        background.zPosition = -1
        addChild(background)
    }
    
    
    
    
    // MARK: - Manual Sign-In Setup
    func setupManualSignIn() {
        // Calculate positions with proper spacing
        let inputBoxWidth: CGFloat = 320
        let inputBoxHeight: CGFloat = 55
        let buttonWidth: CGFloat = 180
        let buttonHeight: CGFloat = 55
        
        // Position elements with much more spacing from top
        let startY: CGFloat = size.height * 0.3  // Start at 30% from top
        let spacing: CGFloat = 120  // Much more space between each element
        
        // Create UITextField for Username with improved styling
        usernameTextField = UITextField()
        usernameTextField.placeholder = "請輸入用戶名稱"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        usernameTextField.textColor = .black
        usernameTextField.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.layer.cornerRadius = 12
        usernameTextField.layer.borderWidth = 2
        usernameTextField.layer.borderColor = UIColor.systemBlue.cgColor
        usernameTextField.frame = CGRect(x: 0, y: 0, width: inputBoxWidth, height: inputBoxHeight)
        usernameTextField.center = CGPoint(x: size.width / 2, y: startY)
        usernameTextField.tag = 1
        usernameTextField.delegate = self
        
        // Create UITextField for Password with improved styling
        passwordTextField = UITextField()
        passwordTextField.placeholder = "請輸入密碼"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        passwordTextField.textColor = .black
        passwordTextField.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.layer.cornerRadius = 12
        passwordTextField.layer.borderWidth = 2
        passwordTextField.layer.borderColor = UIColor.systemBlue.cgColor
        passwordTextField.frame = CGRect(x: 0, y: 0, width: inputBoxWidth, height: inputBoxHeight)
        passwordTextField.center = CGPoint(x: size.width / 2, y: startY + spacing)
        passwordTextField.tag = 2
        passwordTextField.delegate = self
        
        // Add text fields to the view
        if let view = self.view {
            view.addSubview(usernameTextField)
            view.addSubview(passwordTextField)
        }
        
        // Calculate button positions relative to password field
        // Convert UIKit coordinates to SpriteKit coordinates
        let passwordFieldBottomY = passwordTextField.center.y + (inputBoxHeight / 2)
        let buttonSpacing: CGFloat = 100  // Space between buttons and password field
        
        // Sign-In Button positioned below password field
        signInButtonBackground = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 15)
        signInButtonBackground.fillColor = UIColor.systemBlue
        signInButtonBackground.strokeColor = UIColor.systemBlue
        signInButtonBackground.lineWidth = 2
        // Convert UIKit Y to SpriteKit Y (flip coordinate system)
        let signInButtonY = size.height - (passwordFieldBottomY + buttonSpacing)
        signInButtonBackground.position = CGPoint(x: size.width / 2, y: signInButtonY)
        addChild(signInButtonBackground)
        
        manualSignInButton = SKLabelNode(text: "開始遊戲")
        manualSignInButton.fontSize = 24
        manualSignInButton.fontColor = .white
        manualSignInButton.fontName = "AvenirNext-Bold"
        manualSignInButton.position = signInButtonBackground.position
        manualSignInButton.name = "manualSignInButton"
        addChild(manualSignInButton)
        
        // Reset Button positioned below sign-in button
        resetButtonBackground = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 15)
        resetButtonBackground.fillColor = UIColor.systemGray
        resetButtonBackground.strokeColor = UIColor.systemGray
        resetButtonBackground.lineWidth = 2
        // Position below sign-in button
        let resetButtonY = signInButtonY - (buttonHeight + 20)
        resetButtonBackground.position = CGPoint(x: size.width / 2, y: resetButtonY)
        addChild(resetButtonBackground)
        
        resetButton = SKLabelNode(text: "重新開始")
        resetButton.fontSize = 24
        resetButton.fontColor = .white
        resetButton.fontName = "AvenirNext-Bold"
        resetButton.position = resetButtonBackground.position
        resetButton.name = "resetButton"
        addChild(resetButton)

    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let touchedNode = atPoint(location)
            
            if touchedNode.name == "manualSignInButton" {
                // ✅ Change colors when pressed
                signInButtonBackground.fillColor = UIColor.systemBlue.withAlphaComponent(0.7)
                manualSignInButton.fontColor = .white
                
                // Get values from text fields
                enteredUsername = usernameTextField.text ?? ""
                enteredPassword = passwordTextField.text ?? ""
                
                authenticateWithUsernamePassword()
            } else if touchedNode.name == "resetButton" {  // ✅ Handle Reset Progress
                resetButtonBackground.fillColor = UIColor.systemGray.withAlphaComponent(0.7)
                resetButton.fontColor = .white
                resetProgress()
            }
        }
    }
    
    // MARK: - UITextFieldDelegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Clear placeholder text when user starts typing
        if textField.text == "" {
            textField.placeholder = textField.tag == 1 ? "登入名稱" : "輸入密碼"
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Update the entered values
        if textField.tag == 1 {
            enteredUsername = textField.text ?? ""
        } else if textField.tag == 2 {
            enteredPassword = textField.text ?? ""
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 1 {
            // Move to password field when username is entered
            passwordTextField.becomeFirstResponder()
        } else if textField.tag == 2 {
            // Dismiss keyboard and attempt login when password is entered
            textField.resignFirstResponder()
            enteredUsername = usernameTextField.text ?? ""
            enteredPassword = passwordTextField.text ?? ""
            authenticateWithUsernamePassword()
        }
        return true
    }
    
    // ✅ Reset Progress
    func resetProgress() {
            print("🚨 Resetting progress and transitioning to IntroductionScene...")

            // ✅ Reset all user progress
            UserDefaults.standard.set(false, forKey: "hasSeenIntro")  // ✅ Mark intro as unseen
            UserDefaults.standard.set(0, forKey: "gameScore")
            UserDefaults.standard.set(0, forKey: "crystalCoins")
            UserDefaults.standard.synchronize()  // ✅ Ensure settings are saved immediately

            // ✅ Ensure a clean transition
            removeAllChildren()
            removeAllActions()

            let introScene = IntroductionScene(size: size)
            introScene.scaleMode = .aspectFill
            self.view?.presentScene(introScene, transition: SKTransition.fade(withDuration: 1.5))

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // ✅ Restore original colors after press is released
        signInButtonBackground.fillColor = UIColor.systemBlue
        manualSignInButton.fontColor = .white
        resetButtonBackground.fillColor = UIColor.systemGray
        resetButton.fontColor = .white
    }
    
    
    
    // MARK: - Authenticate User via Username & Password
    func authenticateWithUsernamePassword() {
        let url = URL(string: "https://jkcorp.pythonanywhere.com/login")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": enteredUsername,
            "password": enteredPassword
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Network error")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    print("Login Success")
                    self.hideLoginUI()
                    self.transitionToGameScene()
                }
            } else {
                print("Invalid response from server")
            }
        }.resume()
    }
    
    // MARK: - Hide Login UI
    func hideLoginUI() {
        // Remove UITextField objects
        usernameTextField?.removeFromSuperview()
        passwordTextField?.removeFromSuperview()
        
        // Remove SpriteKit nodes
        signInButtonBackground?.removeFromParent()
        manualSignInButton?.removeFromParent()
        resetButtonBackground?.removeFromParent()
        resetButton?.removeFromParent()
    }
    
    // MARK: - Transition to Game Scene
    func transitionToGameScene() {
        let hasSeenIntro = UserDefaults.standard.bool(forKey: "hasSeenIntro")
        let nextScene: SKScene
        if hasSeenIntro {
            nextScene = WelcomeBackScene(size: size)  // ✅ Skip intro if seen
        } else {
            nextScene = IntroductionScene(size: size)  // ✅ Show intro first
        }

        nextScene.scaleMode = .aspectFill
        self.view?.presentScene(nextScene, transition: SKTransition.fade(withDuration: 1.5))
    }


}
