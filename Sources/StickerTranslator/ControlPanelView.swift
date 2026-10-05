import SwiftUI

/// The small control panel: toggle, language, and status line.
struct ControlPanelView: View {
    @Bindable var state: AppState

    var body: some View {
        Form {
            Toggle("Always translate images", isOn: $state.isTranslating)
                .disabled(state.readiness != .ready)
            LabeledContent("Language", value: "Spanish → English")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if state.readiness == .needsScreenPermission {
                Button("Grant Screen Permission…") { state.requestScreenPermission() }
                Text("After granting it, quit and reopen Sticker Translator.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 340)
        .fixedSize()
        .onAppear { state.refresh() }
    }

    private var statusColor: Color {
        state.readiness == .ready ? .green : .orange
    }

    private var statusText: String {
        guard state.readiness == .ready else { return state.readiness.message }
        return state.isTranslating ? "Running — watching WhatsApp for Spanish stickers" : "Ready — turn on the toggle to start"
    }
}
