import SwiftUI
import UIKit

struct FastTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var onSubmit: (() -> Void)? = nil

    func makeUIView(context: Context) -> UITextField {
        let textField = isSecure ? UITextField() : UITextField()
        if isSecure {
            let secureField = UITextField()
            secureField.isSecureTextEntry = true
            return setup(secureField, context: context)
        }
        return setup(textField, context: context)
    }

    private func setup(_ textField: UITextField, context: Context) -> UITextField {
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textContentType = textContentType
        textField.autocorrectionDisabled = true
        textField.autocapitalizationType = .none
        textField.font = .preferredFont(forTextStyle: .body)
        textField.borderStyle = .none
        
        // Disable the shortcut bar (Assistant Bar) to fix the constraint error
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FastTextField

        init(_ parent: FastTextField) {
            self.parent = parent
        }

        @objc func textChanged(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            parent.onSubmit?()
            return true
        }
    }
}

private extension UITextField {
    var autocorrectionDisabled: Bool {
        get { autocorrectionType == .no }
        set { autocorrectionType = newValue ? .no : .default }
    }
}

