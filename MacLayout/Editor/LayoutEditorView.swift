import SwiftUI

struct LayoutEditorView: View {
    @State private var layoutStore = AppState.shared.layoutStore
    @State private var selectedLayoutID: UUID?
    @State private var editingName: String = ""
    @State private var isRenamingID: UUID?

    private var selectedLayout: Layout? {
        guard let id = selectedLayoutID else { return nil }
        return layoutStore.layouts.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            if let layout = selectedLayout,
               let index = layoutStore.layouts.firstIndex(where: { $0.id == layout.id }) {
                ZoneEditorView(root: $layoutStore.layouts[index].root, onChanged: {
                    layoutStore.save()
                })
                .padding()
                .navigationTitle(layout.name)
            } else {
                Text("Select a layout to edit")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedLayoutID == nil {
                selectedLayoutID = layoutStore.layouts.first?.id
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selectedLayoutID) {
                ForEach(layoutStore.layouts) { layout in
                    Group {
                        if isRenamingID == layout.id {
                            TextField("Name", text: $editingName, onCommit: {
                                renameLayout(id: layout.id, name: editingName)
                            })
                            .textFieldStyle(.roundedBorder)
                        } else {
                            HStack {
                                Text(layout.name)
                                Spacer()
                                Text("\(layout.root.leafCount) zones")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contextMenu {
                                Button("Rename") {
                                    editingName = layout.name
                                    isRenamingID = layout.id
                                }
                                Button("Duplicate") {
                                    duplicateLayout(layout)
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    deleteLayout(id: layout.id)
                                }
                                .disabled(layoutStore.layouts.count <= 1)
                            }
                        }
                    }
                    .tag(layout.id)
                }
            }

            Divider()

            HStack {
                Button(action: addLayout) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(action: { deleteLayout(id: selectedLayoutID) }) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(selectedLayoutID == nil || layoutStore.layouts.count <= 1)
            }
            .padding(8)
        }
    }

    private func addLayout() {
        let layout = Layout(name: "New Layout", root: .leaf(id: UUID()))
        layoutStore.addLayout(layout)
        selectedLayoutID = layout.id
    }

    private func deleteLayout(id: UUID?) {
        guard let id = id else { return }
        layoutStore.deleteLayout(id: id)
        selectedLayoutID = layoutStore.layouts.first?.id
    }

    private func duplicateLayout(_ layout: Layout) {
        let copy = Layout(name: layout.name + " Copy", root: layout.root)
        layoutStore.addLayout(copy)
        selectedLayoutID = copy.id
    }

    private func renameLayout(id: UUID, name: String) {
        if var layout = layoutStore.layouts.first(where: { $0.id == id }) {
            layout.name = name.isEmpty ? "Untitled" : name
            layoutStore.updateLayout(layout)
        }
        isRenamingID = nil
    }
}
