import AppKit

/// Opening kitty windows (Shoji assumes kitty is installed).
@MainActor
enum Kitty {
    /// A new kitty window running `command` (each `open -n` is a new kitty instance, so the window
    /// closes with its command). `hold`: keep the window open after the command ends, so its last
    /// output (an exited `docker run`, a stopped log stream) can still be read.
    /// False when kitty isn't installed (nothing would open).
    @discardableResult
    static func open(title: String, _ command: [String], hold: Bool = false) -> Bool {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "net.kovidgoyal.kitty") != nil else { return false }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-n", "-b", "net.kovidgoyal.kitty", "--args", "--title", title] + (hold ? ["--hold"] : []) + command
        do { try p.run() } catch { return false }
        return true
    }
}
