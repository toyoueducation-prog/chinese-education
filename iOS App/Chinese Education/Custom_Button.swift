import SwiftUI

struct CustomButton: View {
    enum ButtonStyleType {
        case primary
        case secondary
        case success
        case warning
        case danger
        case custom(Color, Color)  // background, textColor
    }

    var title: String
    var icon: String? = nil
    var style: ButtonStyleType
    var action: () -> Void

    private func getColors() -> (background: Color, text: Color) {
        switch style {
        case .primary:
            return (.blue, .white)
        case .secondary:
            return (.gray, .white)
        case .success:
            return (.green, .white)
        case .warning:
            return (.orange, .white)
        case .danger:
            return (.red, .white)
        case .custom(let background, let text):
            return (background, text)
        }
    }

    var body: some View {
        let colors = getColors()

        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colors.text)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(colors.text)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(colors.background)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 3)
        }
        .padding(.horizontal, 20)
    }
}
