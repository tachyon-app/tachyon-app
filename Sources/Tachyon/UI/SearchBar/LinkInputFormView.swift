import SwiftUI
import AppKit

struct LinkInputFormView: View {
    let link: CustomLinkRecord
    let onExecute: (URL) -> Void
    let onCancel: () -> Void
    
    @State private var paramValues: [String: String] = [:]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                if let iconData = link.icon, let image = NSImage(data: iconData) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "link")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text(link.name)
                        .font(.headline)
                    Text(link.urlTemplate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            
            Divider()
            
            // Parameters
            VStack(alignment: .leading, spacing: 12) {
                Text("Enter Parameters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(link.parameters, id: \.self) { param in
                    HStack {
                        Text(param)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 120, alignment: .leading)
                        
                        TextField(link.defaults[param] ?? "Value", text: Binding(
                            get: { paramValues[param] ?? link.defaults[param] ?? "" },
                            set: { paramValues[param] = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding(.horizontal, 18)
            
            // Actions
            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Open") {
                    executeLink()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(width: 650)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
    
    private func executeLink() {
        if let url = link.constructURL(values: paramValues) {
            onExecute(url)
        }
    }
}
