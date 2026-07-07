import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var vm: PopoverViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if vm.sessions.count > 1 { sessionPicker }
            fields
            statusArea
            runButton
        }
        .padding(16)
        .frame(width: 380)
    }

    private var header: some View {
        HStack {
            Text("Continue Session").font(.headline)
            Spacer()
            Button {
                vm.refresh()
            } label: {
                Image(systemName: "arrow.clockwise").font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Refresh sessions")
        }
    }

    private var sessionPicker: some View {
        row(label: "Session") {
            Picker("", selection: Binding(
                get: { vm.selectedSessionId },
                set: { vm.selectSession(id: $0) }
            )) {
                ForEach(vm.sessions) { s in
                    Text(String(s.sessionId.prefix(24))).tag(s.sessionId)
                }
            }
        }
    }

    private var fields: some View {
        VStack(spacing: 10) {
            row(label: "Time (hrs)") {
                TextField("1.0", text: $vm.timeValue)
                    .textFieldStyle(.roundedBorder)
            }
            row(label: "Directory") {
                TextField("", text: $vm.directory)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            }
            row(label: "Session ID") {
                TextField("", text: $vm.sessionId)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
            }
        }
    }

    @ViewBuilder
    private var statusArea: some View {
        if !vm.statusMessage.isEmpty {
            Text(vm.statusMessage)
                .font(.system(size: 11))
                .foregroundColor(vm.isError ? .red : .green)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    private var runButton: some View {
        Button(action: vm.runCommand) {
            Group {
                if vm.isRunning {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Scheduling…")
                    }
                } else {
                    Text("Run")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!vm.canRun)
    }

    private func row<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .frame(width: 72, alignment: .trailing)
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            content()
        }
    }
}
