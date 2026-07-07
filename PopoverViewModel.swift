import Foundation

class PopoverViewModel: ObservableObject {
    @Published var timeValue: String = "1.0"
    @Published var directory: String = ""
    @Published var sessionId: String = ""
    @Published var sessions: [ClaudeSession] = []
    @Published var selectedSessionId: String = ""
    @Published var statusMessage: String = ""
    @Published var isError: Bool = false
    @Published var isRunning: Bool = false

    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            let found = findClaudeSessions()
            DispatchQueue.main.async {
                self.sessions = found
                if let first = found.first {
                    self.selectedSessionId = first.sessionId
                    self.sessionId = first.sessionId
                    self.directory = first.workingDirectory
                }
            }
        }
    }

    func selectSession(id: String) {
        guard let session = sessions.first(where: { $0.sessionId == id }) else { return }
        selectedSessionId = session.sessionId
        sessionId = session.sessionId
        directory = session.workingDirectory
        statusMessage = ""
    }

    func runCommand() {
        let t = timeValue.trimmingCharacters(in: .whitespaces)
        let d = directory.trimmingCharacters(in: .whitespaces)
        let s = sessionId.trimmingCharacters(in: .whitespaces)

        isRunning = true
        statusMessage = ""
        isError = false

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", "/opt/homebrew/bin/continueSession '\(t)' '\(d)' '\(s)' -b"]

            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
            process.environment = env

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = (String(data: data, encoding: .utf8) ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let code = process.terminationStatus

                DispatchQueue.main.async {
                    self.isRunning = false
                    self.isError = code != 0
                    if code == 0 {
                        self.statusMessage = output.isEmpty ? "Scheduled successfully." : output
                    } else {
                        self.statusMessage = output.isEmpty
                            ? "Failed (exit \(code))."
                            : output
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.isError = true
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    var canRun: Bool {
        !isRunning
            && !timeValue.trimmingCharacters(in: .whitespaces).isEmpty
            && !directory.trimmingCharacters(in: .whitespaces).isEmpty
            && !sessionId.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
