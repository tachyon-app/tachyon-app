import SwiftUI

/// Form for collecting script arguments before execution
struct ScriptArgumentInputView: View {
    let script: ScriptRecord
    let metadata: ScriptMetadata
    let onExecute: ([Int: String]) -> Void
    let onCancel: () -> Void
    
    @State private var argumentValues: [Int: String] = [:]
    @FocusState private var focusedField: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(script.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
            
            // Form fields
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(metadata.arguments, id: \.position) { argument in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(argument.placeholder)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                if !argument.optional {
                                    Text("*")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            if argument.type == .password {
                                SecureField("", text: binding(for: argument.position))
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .focused($focusedField, equals: argument.position)
                            } else {
                                TextField(argument.placeholder, text: binding(for: argument.position))
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .focused($focusedField, equals: argument.position)
                            }
                        }
                    }
                }
                .padding(24)
            }
            
            // Footer
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button(action: handleExecute) {
                    Text("Run Script")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#3B86F7"))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!isValid)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(hex: "#1a1a1a"))
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .frame(width: 500)
        .background(Color(hex: "#1f1f1f"))
        .cornerRadius(12)
        .onAppear {
            // Initialize with empty values
            for arg in metadata.arguments {
                argumentValues[arg.position] = ""
            }
            // Focus first field
            focusedField = metadata.arguments.first?.position
        }
    }
    
    private func binding(for position: Int) -> Binding<String> {
        Binding(
            get: { argumentValues[position] ?? "" },
            set: { argumentValues[position] = $0 }
        )
    }
    
    private var isValid: Bool {
        // Check all required arguments are filled
        for arg in metadata.arguments where !arg.optional {
            if argumentValues[arg.position]?.isEmpty ?? true {
                return false
            }
        }
        return true
    }
    
    private func handleExecute() {
        onExecute(argumentValues)
    }
}

/// Custom text field style matching Raycast
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}
