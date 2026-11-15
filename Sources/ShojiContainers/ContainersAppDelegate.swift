import AppKit

/// Shoji Containers: the companion app for Docker containers and images (dev.shoji.Containers) —
/// a regular app with a Dock icon whose Containers window Shoji tiles like any other.
@MainActor
final class ContainersAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    nonisolated static let bundleID = "dev.shoji.Containers"

    private var window: NSWindow!
    private var containers: ContainersApp!
    private var keyMonitor: Any?

    private var signalSources: [DispatchSourceSignal] = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Only one Shoji Containers at a time.
        if ProcessInfo.processInfo.environment["SHOJI_CONTAINERS_TEST"] == nil,
           let other = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID)
            .first(where: { $0.processIdentifier != getpid() }) {
            other.activate()
            NSApp.terminate(nil)
            return
        }
        // `kill` / logout: quit properly (streams closed).
        for sig in [SIGTERM, SIGINT, SIGHUP] {
            signal(sig, SIG_IGN)
            let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            src.setEventHandler { NSApp.terminate(nil) }
            src.resume()
            signalSources.append(src)
        }
        Config.shared.load()
        buildMenus()
        containers = ContainersApp()
        window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 920, height: 560),
                          styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Containers"
        window.contentView = containers.view
        window.isReleasedWhenClosed = false
        // See-through like the terminals: the view draws its own (translucent) background.
        window.isOpaque = false
        window.backgroundColor = .clear
        applyTitlebar()
        NotificationCenter.default.addObserver(forName: .configDidChange, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyTitlebar() }
        }
        window.delegate = self
        window.setFrameAutosaveName("ShojiContainers")
        if !window.setFrameUsingName("ShojiContainers") { window.center() }

        // Theme picked in Shoji (another process): reload the shared settings and recolour.
        DistributedNotificationCenter.default().addObserver(forName: Config.changedAcrossApps, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                Config.shared.load()
                Config.shared.notifyChanged()
            }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            nonisolated(unsafe) let event = e // delivered on the main thread
            let handled = MainActor.assumeIsolated { () -> Bool in
                guard let self, event.window === self.window, !(self.window.firstResponder is NSText) else { return false }
                return self.containers.handleKey(event)
            }
            return handled ? nil : e
        }
        if ContainersTest.run() { return } // scripted test (SHOJI_CONTAINERS_TEST), headless
        showWindow()
    }

    /// Like kitty with hide_window_decorations titlebar-only: no title bar or traffic lights, but
    /// still resizable (and movable by its background, though Shoji places it anyway).
    private func applyTitlebar() {
        let hide = Config.shared.hideTitlebar
        if hide { window.styleMask.insert(.fullSizeContentView) } else { window.styleMask.remove(.fullSizeContentView) }
        window.titlebarAppearsTransparent = hide
        window.titleVisibility = hide ? .hidden : .visible
        window.isMovableByWindowBackground = hide
        window.contentView?.needsLayout = true // content moves below (or up into) the title bar area
        for b in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(b)?.isHidden = hide
        }
    }

    private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        containers.focus()
    }

    // The Dock icon (or Mod+O in Shoji) brings the window back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    /// Closing the window quits (nothing runs in here once it's closed).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        containers?.shutdown()
    }

    private func buildMenus() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Shoji Containers", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Shoji Containers", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Shoji Containers", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        main.addItem(editItem)

        let windowItem = NSMenuItem()
        let win = NSMenu(title: "Window")
        win.addItem(withTitle: "Containers", action: #selector(showContainers), keyEquivalent: "0").target = self
        win.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        win.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowItem.submenu = win
        main.addItem(windowItem)
        NSApp.mainMenu = main
        NSApp.windowsMenu = win
    }

    @objc private func showContainers() { showWindow() }
}
