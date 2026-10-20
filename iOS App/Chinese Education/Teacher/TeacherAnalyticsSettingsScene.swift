import SpriteKit
#if os(iOS)
import UIKit
#endif

/**
 * Teacher settings for the Insight Meter analytics server.
 * Stores base URL + class ID in UserDefaults; ingest/admin tokens in Keychain.
 * Creating a class (POST /classes) shows the invite code for students.
 */
class TeacherAnalyticsSettingsScene: SKScene, UITextFieldDelegate {
    private var backButton: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var inviteCodeLabel: SKLabelNode!

    #if os(iOS)
    private var baseURLField: UITextField!
    private var classIDField: UITextField!
    private var ingestTokenField: UITextField!
    private var adminTokenField: UITextField!
    private var classNameField: UITextField!
    private var textFields: [UITextField] = []
    #endif

    private var isInitialized = false

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
        isInitialized = false
        removeAllChildren()
        setupChrome()
        #if os(iOS)
        setupFields(in: view)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.isInitialized = true
        }
    }

    override func willMove(from view: SKView) {
        #if os(iOS)
        textFields.forEach { $0.removeFromSuperview() }
        textFields.removeAll()
        #endif
        super.willMove(from: view)
    }

    private func setupChrome() {
        let title = SKLabelNode(text: "分析伺服器設定")
        title.fontSize = 26
        title.fontColor = .black
        title.fontName = "AvenirNext-Bold"
        title.position = CGPoint(x: size.width / 2, y: safeTopY - 28)
        title.zPosition = 10
        addChild(title)

        let backBg = SKShapeNode(rectOf: CGSize(width: 100, height: 44), cornerRadius: 8)
        backBg.fillColor = UIColor.white.withAlphaComponent(0.9)
        backBg.strokeColor = UIColor.systemGray4
        backBg.position = CGPoint(x: safeInsets.left + 60, y: safeTopY - 28)
        backBg.name = "backButton"
        backBg.zPosition = 100
        addChild(backBg)

        backButton = SKLabelNode(text: "← 返回")
        backButton.fontSize = 18
        backButton.fontColor = .systemBlue
        backButton.fontName = "AvenirNext-Medium"
        backButton.position = backBg.position
        backButton.name = "backButton"
        backButton.zPosition = 101
        addChild(backButton)

        addActionButton(title: "儲存設定", name: "saveSettings",
                        color: .systemBlue,
                        x: size.width / 2 - 90,
                        y: safeBottomY + 120)
        addActionButton(title: "建立班級", name: "createClass",
                        color: .systemGreen,
                        x: size.width / 2 + 90,
                        y: safeBottomY + 120)

        statusLabel = SKLabelNode(text: "令牌僅存於 Keychain，不會寫入原始碼")
        statusLabel.fontSize = 13
        statusLabel.fontColor = .darkGray
        statusLabel.fontName = "AvenirNext-Medium"
        statusLabel.numberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = size.width - 48
        statusLabel.verticalAlignmentMode = .top
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.position = CGPoint(x: size.width / 2, y: safeBottomY + 88)
        statusLabel.zPosition = 10
        addChild(statusLabel)

        inviteCodeLabel = SKLabelNode(text: "")
        inviteCodeLabel.fontSize = 16
        inviteCodeLabel.fontColor = .systemIndigo
        inviteCodeLabel.fontName = "AvenirNext-Bold"
        inviteCodeLabel.numberOfLines = 0
        inviteCodeLabel.preferredMaxLayoutWidth = size.width - 48
        inviteCodeLabel.verticalAlignmentMode = .center
        inviteCodeLabel.horizontalAlignmentMode = .center
        inviteCodeLabel.position = CGPoint(x: size.width / 2, y: safeBottomY + 52)
        inviteCodeLabel.zPosition = 10
        addChild(inviteCodeLabel)

        if let classID = AnalyticsServerConfig.classID {
            inviteCodeLabel.text = "目前班級 ID：\(classID)"
        }
    }

    private func addActionButton(title: String, name: String, color: UIColor, x: CGFloat, y: CGFloat) {
        let bg = SKShapeNode(rectOf: CGSize(width: 150, height: 44), cornerRadius: 10)
        bg.fillColor = color
        bg.strokeColor = color
        bg.position = CGPoint(x: x, y: y)
        bg.name = name
        bg.zPosition = 20
        addChild(bg)
        let label = SKLabelNode(text: title)
        label.fontSize = 16
        label.fontColor = .white
        label.fontName = "AvenirNext-Bold"
        label.position = bg.position
        label.name = name
        label.zPosition = 21
        addChild(label)
    }

    #if os(iOS)
    private func setupFields(in view: SKView) {
        let topInset = view.safeAreaInsets.top
        let fieldWidth = min(size.width - 40, 360)
        let fieldHeight: CGFloat = 44
        let startY = topInset + 90
        let spacing: CGFloat = 58
        let centerX = size.width / 2

        baseURLField = makeField(
            placeholder: "分析伺服器 URL",
            text: AnalyticsServerConfig.baseURLString,
            y: startY,
            width: fieldWidth,
            height: fieldHeight,
            centerX: centerX,
            secure: false
        )
        classIDField = makeField(
            placeholder: "班級 ID（數字）",
            text: AnalyticsServerConfig.classID.map(String.init) ?? "",
            y: startY + spacing,
            width: fieldWidth,
            height: fieldHeight,
            centerX: centerX,
            secure: false
        )
        classIDField.keyboardType = .numberPad

        ingestTokenField = makeField(
            placeholder: "上傳令牌（ingest）",
            text: AnalyticsServerConfig.ingestToken,
            y: startY + spacing * 2,
            width: fieldWidth,
            height: fieldHeight,
            centerX: centerX,
            secure: true
        )
        adminTokenField = makeField(
            placeholder: "教師令牌（admin）",
            text: AnalyticsServerConfig.adminToken,
            y: startY + spacing * 3,
            width: fieldWidth,
            height: fieldHeight,
            centerX: centerX,
            secure: true
        )
        classNameField = makeField(
            placeholder: "新班級名稱（建立用）",
            text: "",
            y: startY + spacing * 4,
            width: fieldWidth,
            height: fieldHeight,
            centerX: centerX,
            secure: false
        )

        textFields = [baseURLField, classIDField, ingestTokenField, adminTokenField, classNameField]
        textFields.forEach { view.addSubview($0) }
    }

    private func makeField(
        placeholder: String,
        text: String,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        centerX: CGFloat,
        secure: Bool
    ) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.text = text
        field.borderStyle = .roundedRect
        field.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        field.textColor = .black
        field.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.isSecureTextEntry = secure
        field.layer.cornerRadius = 10
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.systemGray4.cgColor
        field.frame = CGRect(x: 0, y: 0, width: width, height: height)
        field.center = CGPoint(x: centerX, y: y)
        field.delegate = self
        return field
    }
    #endif

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isInitialized, let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        #if os(iOS)
        textFields.forEach { $0.resignFirstResponder() }
        #endif

        if node.name == "backButton" || node.parent?.name == "backButton" {
            #if os(iOS)
            textFields.forEach { $0.removeFromSuperview() }
            #endif
            let dash = TeacherDashboardScene(size: size)
            dash.scaleMode = .aspectFill
            view?.presentScene(dash, transition: SKTransition.fade(withDuration: 0.35))
        } else if node.name == "saveSettings" || node.parent?.name == "saveSettings" {
            saveSettings()
        } else if node.name == "createClass" || node.parent?.name == "createClass" {
            createClass()
        }
    }

    private func saveSettings() {
        #if os(iOS)
        let urlText = baseURLField.text ?? ""
        AnalyticsServerConfig.baseURLString = urlText.isEmpty
            ? AnalyticsServerConfig.defaultBaseURLString
            : urlText
        AnalyticsServerConfig.ingestToken = ingestTokenField.text ?? ""
        AnalyticsServerConfig.adminToken = adminTokenField.text ?? ""
        let classText = (classIDField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if classText.isEmpty {
            AnalyticsServerConfig.classID = nil
        } else if let id = Int(classText) {
            AnalyticsServerConfig.classID = id
        }
        baseURLField.text = AnalyticsServerConfig.baseURLString
        statusLabel.text = "已儲存。內容／登入仍使用 jkcorp；分析用此 URL。"
        if let id = AnalyticsServerConfig.classID {
            inviteCodeLabel.text = "目前班級 ID：\(id)"
        }
        #endif
    }

    private func createClass() {
        #if os(iOS)
        saveSettings()
        let name = (classNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            statusLabel.text = "請先輸入新班級名稱"
            return
        }
        guard AnalyticsServerConfig.isAdminConfigured else {
            statusLabel.text = "需要教師 admin 令牌才能建立班級"
            return
        }
        statusLabel.text = "建立班級中…"
        AnalyticsAPIClient.shared.createClass(name: name) { [weak self] dto in
            guard let self else { return }
            if let dto {
                AnalyticsServerConfig.classID = dto.id
                self.classIDField.text = String(dto.id)
                self.inviteCodeLabel.text = "邀請碼：\(dto.invite_code)（班級 ID \(dto.id)）"
                self.statusLabel.text = "班級「\(dto.name)」已建立 — 請把邀請碼給學生"
            } else {
                self.statusLabel.text = "建立失敗（網路或令牌）。本地儀表板仍可用。"
            }
        }
        #endif
    }
}
