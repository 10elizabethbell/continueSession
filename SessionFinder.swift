import Foundation

struct ClaudeSession: Identifiable, Hashable {
    var id: String { sessionId }
    let pid: pid_t
    let sessionId: String
    let workingDirectory: String
    let name: String?

    var displayName: String {
        let dir = (workingDirectory as NSString).lastPathComponent
        if let name, !name.isEmpty { return "\(dir) — \(name)" }
        return dir.isEmpty ? sessionId : dir
    }
}

// Sessions are read from ~/.claude/sessions/<pid>.json rather than by scanning
// process environments: CLAUDE_CODE_SESSION_ID is inherited by every child a
// session spawns (node, git, compilers, the continueSession script itself), so
// env scanning yields duplicates and picks a child's misleading cwd. The session
// files hold the authoritative cwd, one entry per session, and are the same
// source the continueSession script validates against — so anything shown here
// is guaranteed to resume cleanly.
func findClaudeSessions() -> [ClaudeSession] {
    let dir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/sessions", isDirectory: true)
    guard let files = try? FileManager.default.contentsOfDirectory(
        at: dir, includingPropertiesForKeys: nil) else { return [] }

    var byId: [String: ClaudeSession] = [:]
    var startedAt: [String: Double] = [:]

    for file in files where file.pathExtension == "json" {
        guard let data = try? Data(contentsOf: file),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sid = obj["sessionId"] as? String,
              let pidNum = obj["pid"] as? Int else { continue }

        let pid = pid_t(pidNum)
        guard isAlive(pid) else { continue }               // skip stale files for dead sessions
        if obj["kind"] as? String == "bg" { continue }     // only terminal-attached sessions

        let cwd = (obj["cwd"] as? String) ?? "/"
        let name = obj["name"] as? String
        let started = (obj["startedAt"] as? Double) ?? 0

        // If a session id ever appears in two files, keep the most recent.
        if let existing = startedAt[sid], existing >= started { continue }
        startedAt[sid] = started
        byId[sid] = ClaudeSession(pid: pid, sessionId: sid, workingDirectory: cwd, name: name)
    }

    // Newest session first — the best guess for the terminal in front.
    return byId.values.sorted { (startedAt[$0.sessionId] ?? 0) > (startedAt[$1.sessionId] ?? 0) }
}

private func isAlive(_ pid: pid_t) -> Bool {
    guard pid > 0 else { return false }
    if kill(pid, 0) == 0 { return true }
    return errno == EPERM   // process exists but is owned by another user
}
