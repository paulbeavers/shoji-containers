import Foundation

/// Opening kitty windows (Shoji assumes kitty is installed).
@MainActor
enum Kitty {
    /// A new kitty window running `command` (each `open -n` is a new kitty instance, so the window
    /// closes with its command). `hold`: keep the window open after the command ends, so its last
    /// output (an exited `docker run`, a stopped log stream) can still be read.
    static func open(title: String, _ command: [String], hold: Bool = false) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-n", "-b", "net.kovidgoyal.kitty", "--args", "--title", title] + (hold ? ["--hold"] : []) + command
        try? p.run()
    }
}
