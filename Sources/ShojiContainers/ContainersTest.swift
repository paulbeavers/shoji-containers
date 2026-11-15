import AppKit

/// Scripted check of Shoji Containers against the real Docker daemon, without a window:
/// `SHOJI_CONTAINERS_TEST=<log> "Shoji Containers"`. Only touches throwaway `shoji-test-*`
/// containers and the `alpine:3.20` image it pulls itself, and removes them afterwards.
@MainActor
enum ContainersTest {
    static func run() -> Bool {
        guard let logPath = ProcessInfo.processInfo.environment["SHOJI_CONTAINERS_TEST"] else { return false }
        FileManager.default.createFile(atPath: logPath, contents: nil)
        func log(_ t: String) {
            if let h = FileHandle(forWritingAtPath: logPath) { h.seekToEndOfFile(); h.write(Data("\(t)\n".utf8)) }
        }
        func rows(_ app: ContainersApp) -> [String] {
            func walk(_ v: NSView) -> [NSView] { v.subviews + v.subviews.flatMap(walk) }
            return walk(app.view).compactMap { v -> String? in
                guard let r = v as? DockerRowView else { return nil }
                return "\(type(of: r)): \(r.name.stringValue) | " + r.columns.map { $0.stringValue }.joined(separator: " | ")
            }
        }
        Task { @MainActor in
            let docker = DockerClient.cliPath
            guard let client = DockerClient.discover() else { log("no Docker socket"); NSApp.terminate(nil); return }
            log("socket \(client.socketPath)")
            // Leave the user's own alpine:3.20 alone: only remove it if this test pulled it.
            let hadAlpine = (try? await client.request("GET", "/images/alpine:3.20/json"))?.ok == true
            _ = try? await client.call("POST", "/images/create?fromImage=alpine&tag=3.20", timeout: 120)
            func sh(_ args: [String]) {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: docker)
                p.arguments = args
                p.standardOutput = FileHandle.nullDevice
                p.standardError = FileHandle.nullDevice
                try? p.run()
                p.waitUntilExit()
            }
            sh(["run", "-d", "--name", "shoji-test-web", "-p", "18090:80", "--label", "com.docker.compose.project=shoji-test",
                "--label", "com.docker.compose.service=web", "alpine:3.20", "sleep", "600"])
            sh(["run", "-d", "--name", "shoji-test-solo", "alpine:3.20", "sleep", "600"])
            let app = ContainersApp()
            app.view.frame = CGRect(x: 0, y: 0, width: 1000, height: 600)
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            log("--- containers"); rows(app).forEach(log)
            let images = ContainersApp(tab: .images)
            images.view.frame = CGRect(x: 0, y: 0, width: 1000, height: 600)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            log("--- images"); rows(images).forEach(log)
            sh(["rm", "-f", "shoji-test-web", "shoji-test-solo"])
            if !hadAlpine { sh(["rmi", "alpine:3.20"]) }
            log("cleaned up")
            NSApp.terminate(nil)
        }
        return true
    }
}
