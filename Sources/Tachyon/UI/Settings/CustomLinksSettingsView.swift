import SwiftUI
import AppKit
import GRDB

struct CustomLinksSettingsView: View {
    @StateObject private var viewModel = CustomLinksSettingsViewModel()
    @State private var sheetMode: SheetMode?
    
    enum SheetMode: Identifiable {
        case add
        case edit(CustomLinkRecord)
        
        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let link): return "edit-\(link.id)"
            }
        }
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.links) { link in
                    HStack {
                        if let iconData = link.icon, let image = NSImage(data: iconData) {
                            Image(nsImage: image)
                                .resizable()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "link")
                                .frame(width: 24, height: 24)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(link.name)
                                .font(.headline)
                            Text(link.urlTemplate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !link.parameters.isEmpty {
                                Text("Parameters: \(link.parameters.joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sheetMode = .edit(link)
                    }
                    .contextMenu {
                        Button("Edit") {
                            sheetMode = .edit(link)
                        }
                        Button("Delete", role: .destructive) {
                            viewModel.deleteLink(id: link.id)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteLinkAt)
            }
            .listStyle(.inset)
            
            HStack {
                Spacer()
                Button(action: {
                    sheetMode = .add
                }) {
                    Label("Add Custom Link", systemImage: "plus")
                }
            }
            .padding()
        }
        .sheet(item: $sheetMode) { mode in
            switch mode {
            case .add:
                AddEditCustomLinkView(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { sheetMode != nil },
                        set: { if !$0 { sheetMode = nil } }
                    ),
                    linkToEdit: nil
                )
            case .edit(let link):
                AddEditCustomLinkView(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { sheetMode != nil },
                        set: { if !$0 { sheetMode = nil } }
                    ),
                    linkToEdit: link
                )
            }
        }
        .onAppear {
            viewModel.loadLinks()
        }
    }
}

struct AddEditCustomLinkView: View {
    @ObservedObject var viewModel: CustomLinksSettingsViewModel
    @Binding var isPresented: Bool
    let linkToEdit: CustomLinkRecord?
    
    @State private var name = ""
    @State private var urlTemplate = ""
    @State private var iconData: Data?
    @State private var isFetchingIcon = false
    @State private var defaults: [String: String] = [:]
    
    private var detectedParams: [String] {
        let regex = try! NSRegularExpression(pattern: "\\{\\{([^}]+)\\}\\}", options: [])
        let nsString = urlTemplate as NSString
        let results = regex.matches(in: urlTemplate, options: [], range: NSRange(location: 0, length: nsString.length))
        let params = results.map { nsString.substring(with: $0.range(at: 1)).trimmingCharacters(in: .whitespaces) }
        return Array(Set(params)).sorted()
    }
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Name", text: $name)
                TextField("URL Template", text: $urlTemplate)
                Text("Use {{param}} for placeholders").font(.caption).foregroundColor(.secondary)
            }
            
            if !detectedParams.isEmpty {
                Section(header: Text("Parameters (Default Values)")) {
                    ForEach(detectedParams, id: \.self) { param in
                        HStack {
                            Text(param)
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 100, alignment: .leading)
                            TextField("Default value (optional)", text: Binding(
                                get: { defaults[param] ?? "" },
                                set: { defaults[param] = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                }
            }
            
            Section(header: Text("Icon")) {
                HStack {
                    if isFetchingIcon {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 32, height: 32)
                    } else if let data = iconData, let image = NSImage(data: data) {
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "link")
                            .frame(width: 32, height: 32)
                            .foregroundColor(.secondary)
                    }
                    
                    if !urlTemplate.isEmpty {
                        Button("Refresh Icon") {
                            Task {
                                await fetchIcon()
                            }
                        }
                    }
                }
            }
            
            HStack {
                Button("Cancel") { isPresented = false }
                Spacer()
                Button(linkToEdit == nil ? "Add" : "Save") {
                    save()
                    isPresented = false
                }
                .disabled(name.isEmpty || urlTemplate.isEmpty)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 500, height: 400)
        .onExitCommand {
            isPresented = false
        }
    }
    
    init(viewModel: CustomLinksSettingsViewModel, isPresented: Binding<Bool>, linkToEdit: CustomLinkRecord?) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self.linkToEdit = linkToEdit
        
        // Initialize state from linkToEdit
        if let link = linkToEdit {
            _name = State(initialValue: link.name)
            _urlTemplate = State(initialValue: link.urlTemplate)
            _iconData = State(initialValue: link.icon)
            _defaults = State(initialValue: link.defaults)
        }
    }
    
    func save() {
        if let link = linkToEdit {
            viewModel.updateLink(
                id: link.id,
                name: name,
                urlTemplate: urlTemplate,
                icon: iconData,
                defaults: defaults
            )
        } else {
            viewModel.addLink(
                name: name,
                urlTemplate: urlTemplate,
                icon: iconData,
                defaults: defaults
            )
        }
    }
    
    func fetchIcon() async {
        guard let url = URL(string: urlTemplate), let host = url.host else { return }
        
        isFetchingIcon = true
        defer { isFetchingIcon = false }
        
        let faviconUrlString = "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
        guard let faviconUrl = URL(string: faviconUrlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: faviconUrl)
            iconData = data
        } catch {
            print("❌ Failed to fetch favicon: \(error)")
        }
    }
}

class CustomLinksSettingsViewModel: ObservableObject {
    @Published var links: [CustomLinkRecord] = []
    
    func loadLinks() {
        do {
            links = try StorageManager.shared.getAllCustomLinks()
        } catch {
            print("❌ Failed to load links: \(error)")
        }
    }
    
    func addLink(name: String, urlTemplate: String, icon: Data?, defaults: [String: String]) {
        let link = CustomLinkRecord(
            id: UUID(),
            name: name,
            urlTemplate: urlTemplate,
            icon: icon,
            defaults: defaults
        )
        
        do {
            try StorageManager.shared.saveCustomLink(link)
            loadLinks()
        } catch {
            print("❌ Failed to save link: \(error)")
        }
    }
    
    func updateLink(id: UUID, name: String, urlTemplate: String, icon: Data?, defaults: [String: String]) {
        let link = CustomLinkRecord(
            id: id,
            name: name,
            urlTemplate: urlTemplate,
            icon: icon,
            defaults: defaults
        )
        do {
            try StorageManager.shared.saveCustomLink(link)
            loadLinks()
        } catch {
            print("❌ Failed to update link: \(error)")
        }
    }
    
    func deleteLink(id: UUID) {
        do {
            try StorageManager.shared.deleteCustomLink(id: id)
            loadLinks()
        } catch {
            print("❌ Failed to delete link: \(error)")
        }
    }
    
    func deleteLinkAt(at offsets: IndexSet) {
        offsets.forEach { index in
            let link = links[index]
            deleteLink(id: link.id)
        }
    }
}
