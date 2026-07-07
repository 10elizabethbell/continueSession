import Foundation

struct ClaudeSession: Identifiable, Hashable {
    var id: String { sessionId }
    let pid: pid_t
    let sessionId: String
    let workingDirectory: String
}

func findClaudeSessions() -> [ClaudeSession] {
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
    var size: size_t = 0
    guard sysctl(&mib, 4, nil, &size, nil, 0) == 0, size > 0 else { return [] }

    let count = size / MemoryLayout<kinfo_proc>.stride
    var procs = [kinfo_proc](repeating: kinfo_proc(), count: count + 10)
    // Tell sysctl the true buffer capacity, not the byte count from the sizing
    // call — otherwise the +10 headroom is unused and a process spawned between
    // the two calls makes sysctl return ENOMEM and drops the whole list.
    size = procs.count * MemoryLayout<kinfo_proc>.stride
    guard sysctl(&mib, 4, &procs, &size, nil, 0) == 0 else { return [] }

    let actualCount = size / MemoryLayout<kinfo_proc>.stride
    var sessions: [ClaudeSession] = []

    for i in 0..<actualCount {
        let pid = procs[i].kp_proc.p_pid
        guard pid > 0 else { continue }
        guard let env = processEnvironment(pid: pid),
              let sessionId = env["CLAUDE_CODE_SESSION_ID"] else { continue }

        let cwd = processCWD(pid: pid) ?? env["PWD"] ?? "/"
        sessions.append(ClaudeSession(pid: pid, sessionId: sessionId, workingDirectory: cwd))
    }

    return sessions.sorted { $0.pid > $1.pid }
}

private func processEnvironment(pid: pid_t) -> [String: String]? {
    var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
    var size: size_t = 0
    guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 4 else { return nil }

    var buffer = [UInt8](repeating: 0, count: size)
    guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else { return nil }

    let argc = Int(buffer.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Int32.self) })
    var offset = MemoryLayout<Int32>.size

    // skip exec path
    while offset < buffer.count && buffer[offset] != 0 { offset += 1 }
    while offset < buffer.count && buffer[offset] == 0 { offset += 1 }

    // skip argv strings
    for _ in 0..<argc {
        while offset < buffer.count && buffer[offset] != 0 { offset += 1 }
        while offset < buffer.count && buffer[offset] == 0 { offset += 1 }
    }

    var env: [String: String] = [:]
    while offset < buffer.count && buffer[offset] != 0 {
        let start = offset
        while offset < buffer.count && buffer[offset] != 0 { offset += 1 }
        if let entry = String(bytes: buffer[start..<offset], encoding: .utf8),
           let eqIdx = entry.firstIndex(of: "=") {
            env[String(entry[..<eqIdx])] = String(entry[entry.index(after: eqIdx)...])
        }
        offset += 1
    }

    return env.isEmpty ? nil : env
}

private func processCWD(pid: pid_t) -> String? {
    var vpi = proc_vnodepathinfo()
    let ret = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &vpi, Int32(MemoryLayout<proc_vnodepathinfo>.size))
    guard ret > 0 else { return nil }
    return withUnsafeBytes(of: &vpi.pvi_cdir.vip_path) { raw in
        let ptr = raw.baseAddress!.assumingMemoryBound(to: CChar.self)
        let path = String(cString: ptr)
        return path.isEmpty ? nil : path
    }
}
