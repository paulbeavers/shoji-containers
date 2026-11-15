import AppKit

// macOS's "reopen windows?" prompt after a crash isn't wanted.
UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")

if let i = CommandLine.arguments.firstIndex(of: "--render-icon"), i + 1 < CommandLine.arguments.count {
    MainActor.assumeIsolated { AppIcon.render(to: CommandLine.arguments[i + 1]) }
    exit(0)
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = ContainersAppDelegate()
    app.delegate = delegate
    // A scripted test never appears in the Dock or on screen.
    app.setActivationPolicy(ProcessInfo.processInfo.environment["SHOJI_CONTAINERS_TEST"] == nil ? .regular : .prohibited)
    app.run()
}
