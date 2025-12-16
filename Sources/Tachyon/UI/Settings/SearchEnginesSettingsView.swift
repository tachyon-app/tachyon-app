import SwiftUI
import AppKit
import GRDB

struct SearchEnginesSettingsView: View {
    @StateObject private var viewModel = SearchEnginesSettingsViewModel()
    @State private var showSheet = false
    @State private var editingEngine: SearchEngineRecord?
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.engines) { engine in
                    HStack {
                        if let iconData = engine.icon, let image = NSImage(data: iconData) {
                            Image(nsImage: image)
                                .resizable()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "globe")
                                .frame(width: 24, height: 24)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(engine.name)
                                .font(.headline)
                            Text(engine.urlTemplate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingEngine = engine
                        showSheet = true
                    }
                    .contextMenu {
                        Button("Edit") {
                            editingEngine = engine
                            showSheet = true
                        }
                        Button("Delete", role: .destructive) {
                            viewModel.deleteEngine(id: engine.id)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteEngineAt)
            }
            .listStyle(.inset)
            
            HStack {
                Spacer()
                Button(action: {
                    editingEngine = nil
                    showSheet = true
                }) {
                    Label("Add Search Engine", systemImage: "plus")
                }
            }
            .padding()
        }
        .sheet(isPresented: $showSheet) {
            AddEditSearchEngineView(
                viewModel: viewModel,
                isPresented: $showSheet,
                engineToEdit: editingEngine
            )
        }
        .onAppear {
            viewModel.loadEngines()
        }
    }
}

struct AddEditSearchEngineView: View {
    @ObservedObject var viewModel: SearchEnginesSettingsViewModel
    @Binding var isPresented: Bool
    let engineToEdit: SearchEngineRecord?
    
    @State private var name = ""
    @State private var urlTemplate = ""
    @State private var iconData: Data?
    @State private var isFetchingIcon = false
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Name", text: $name)
                // Keyword removed as per request
                TextField("URL Template", text: $urlTemplate)
                    Text("Use {{query}} as placeholder").font(.caption).foregroundColor(.secondary)
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
                        Image(systemName: "globe")
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
                Button(engineToEdit == nil ? "Add" : "Save") {
                    save()
                    isPresented = false
                }
                .disabled(name.isEmpty || urlTemplate.isEmpty)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            if let engine = engineToEdit {
                name = engine.name
                urlTemplate = engine.urlTemplate
                iconData = engine.icon
            }
        }
        .onExitCommand {
            isPresented = false
        }
        .onChange(of: urlTemplate) { newValue in
            // Basic debounce logic could go here, or just wait for user to finish
        }
    }
    
    func save() {
        if let engine = engineToEdit {
            viewModel.updateEngine(
                id: engine.id,
                name: name,
                keyword: engine.keyword, // Preserve existing keyword or default
                urlTemplate: urlTemplate,
                icon: iconData
            )
        } else {
            viewModel.addEngine(
                name: name,
                keyword: "", // Default empty as requested
                urlTemplate: urlTemplate,
                icon: iconData
            )
        }
    }
    
    func fetchIcon() async {
        guard let url = URL(string: urlTemplate), let host = url.host else { return }
        
        isFetchingIcon = true
        defer { isFetchingIcon = false }
        
        // Use Google's favicon service
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

class SearchEnginesSettingsViewModel: ObservableObject {
    @Published var engines: [SearchEngineRecord] = []
    
    func loadEngines() {
        do {
            engines = try StorageManager.shared.getAllSearchEngines()
        } catch {
            print("❌ Failed to load engines: \(error)")
        }
    }
    
    func addEngine(name: String, keyword: String, urlTemplate: String, icon: Data?) {
        let engine = SearchEngineRecord(
            id: UUID(),
            name: name,
            keyword: keyword,
            urlTemplate: urlTemplate,
            icon: icon
        )
        
        do {
            try StorageManager.shared.saveSearchEngine(engine)
            loadEngines()
        } catch {
            print("❌ Failed to save engine: \(error)")
        }
    }
    
    func updateEngine(id: UUID, name: String, keyword: String, urlTemplate: String, icon: Data?) {
        let engine = SearchEngineRecord(
            id: id,
            name: name,
            keyword: keyword,
            urlTemplate: urlTemplate,
            icon: icon
        )
         do {
            try StorageManager.shared.saveSearchEngine(engine)
            loadEngines()
        } catch {
            print("❌ Failed to update engine: \(error)")
        }
    }
    
    func deleteEngine(id: UUID) {
        do {
            try StorageManager.shared.deleteSearchEngine(id: id)
            loadEngines()
        } catch {
            print("❌ Failed to delete engine: \(error)")
        }
    }
    
    func deleteEngineAt(at offsets: IndexSet) {
        offsets.forEach { index in
            let engine = engines[index]
            deleteEngine(id: engine.id)
        }
    }
}
