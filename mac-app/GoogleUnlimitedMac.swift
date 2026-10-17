import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let output = NSTextView(frame: .zero)
    private let state = NSTextField(labelWithString: "已停止")
    private var watcher: Process?
    private var project: URL {
        // Installed app: ~/googleunlimited/GoogleUnlimited.app, repo script remains beside .app.
        Bundle.main.bundleURL.deletingLastPathComponent()
    }
    private var script: URL { project.appendingPathComponent("google-unlimited.sh") }
    private var watchFile: URL { project.appendingPathComponent("watch_dirs.txt") }
    private var photoFolder: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("GoogleUpload") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        menu.addItem(appItem)
        let sub = NSMenu()
        sub.addItem(withTitle: "結束 GoogleUnlimited", action: #selector(quitApp), keyEquivalent: "q")
        appItem.submenu = sub
        NSApp.mainMenu = menu

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 650, height: 485),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "GoogleUnlimited — Mac"
        window.center()
        window.minSize = NSSize(width: 560, height: 400)

        let base = NSView()
        base.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = base

        let heading = NSTextField(labelWithString: "GoogleUnlimited")
        heading.font = NSFont.boldSystemFont(ofSize: 22)
        heading.translatesAutoresizingMaskIntoConstraints = false
        state.textColor = .secondaryLabelColor
        state.translatesAutoresizingMaskIntoConstraints = false

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 9
        buttons.translatesAutoresizingMaskIntoConstraints = false
        for (title, action) in [
            ("開始上傳", #selector(startUpload)),
            ("停止", #selector(stopUpload)),
            ("上傳統計", #selector(showReport)),
            ("最近紀錄", #selector(showLogs))
        ] {
            let button = NSButton(title: title, target: self, action: action)
            button.bezelStyle = .rounded
            buttons.addArrangedSubview(button)
        }
        let tools = NSStackView()
        tools.orientation = .horizontal
        tools.spacing = 9
        tools.translatesAutoresizingMaskIntoConstraints = false
        for (title, action) in [
            ("選擇資料夾", #selector(chooseFolder)),
            ("開啟資料夾", #selector(openFolder)),
            ("Google Photos", #selector(openPhotos)),
            ("檢查程式", #selector(verify))
        ] {
            let button = NSButton(title: title, target: self, action: action)
            button.bezelStyle = .rounded
            tools.addArrangedSubview(button)
        }

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        output.isEditable = false
        output.isSelectable = true
        output.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        output.textContainerInset = NSSize(width: 10, height: 10)
        scroll.documentView = output

        let notice = NSTextField(wrappingLabelWithString: "本地上傳紀錄不代表已核實雲端檔案。刪除本地副本前，請到 Google Photos 檢查並保留另一份備份。")
        notice.font = NSFont.systemFont(ofSize: 11)
        notice.textColor = .secondaryLabelColor
        notice.translatesAutoresizingMaskIntoConstraints = false

        for v in [heading, state, buttons, tools, scroll, notice] { base.addSubview(v) }
        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: base.topAnchor, constant: 18),
            heading.leadingAnchor.constraint(equalTo: base.leadingAnchor, constant: 20),
            state.centerYAnchor.constraint(equalTo: heading.centerYAnchor),
            state.trailingAnchor.constraint(equalTo: base.trailingAnchor, constant: -20),
            buttons.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 18),
            buttons.leadingAnchor.constraint(equalTo: base.leadingAnchor, constant: 20),
            tools.topAnchor.constraint(equalTo: buttons.bottomAnchor, constant: 10),
            tools.leadingAnchor.constraint(equalTo: base.leadingAnchor, constant: 20),
            scroll.topAnchor.constraint(equalTo: tools.bottomAnchor, constant: 16),
            scroll.leadingAnchor.constraint(equalTo: base.leadingAnchor, constant: 20),
            scroll.trailingAnchor.constraint(equalTo: base.trailingAnchor, constant: -20),
            scroll.bottomAnchor.constraint(equalTo: notice.topAnchor, constant: -12),
            notice.leadingAnchor.constraint(equalTo: base.leadingAnchor, constant: 20),
            notice.trailingAnchor.constraint(equalTo: base.trailingAnchor, constant: -20),
            notice.bottomAnchor.constraint(equalTo: base.bottomAnchor, constant: -16)
        ])
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        append("歡迎使用。先按「選擇資料夾」，再按「開始上傳」。\n")
        if !FileManager.default.fileExists(atPath: script.path) {
            append("錯誤：搵唔到 google-unlimited.sh。請將 .app 放在 repo 根目錄。\n")
        }
    }

    private func append(_ message: String) {
        DispatchQueue.main.async {
            self.output.textStorage?.append(NSAttributedString(string: message))
            self.output.scrollToEndOfDocument(nil)
        }
    }
    private func updateState(_ message: String) {
        DispatchQueue.main.async { self.state.stringValue = message }
    }
    private func command(_ name: String) {
        guard FileManager.default.fileExists(atPath: script.path) else {
            append("未找到 GoogleUnlimited Bash 腳本。\n")
            return
        }
        let bin = script.path
        let folder = project
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = [bin, name]
            task.currentDirectoryURL = folder
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()
                self.append("\n$ " + name + "\n" + (String(data: data, encoding: .utf8) ?? "輸出包含非 UTF-8 字元") + "\n")
            } catch { self.append("錯誤：" + error.localizedDescription + "\n") }
        }
    }

    @objc private func startUpload() {
        guard watcher == nil else { append("上傳監察已在運行。\n"); return }
        guard FileManager.default.fileExists(atPath: watchFile.path),
              let configured = try? String(contentsOf: watchFile, encoding: .utf8),
              !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            append("請先按「選擇資料夾」。\n"); return
        }
        guard FileManager.default.fileExists(atPath: script.path) else { append("搵唔到 Bash 腳本。\n"); return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [script.path, "watch"]
        task.currentDirectoryURL = project
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.watcher = nil
                self?.updateState("已停止")
                self?.append("\n上傳監察已結束。\n")
            }
        }
        do {
            try task.run()
            watcher = task
            updateState("監察上傳中")
            append("開始監察指定資料夾；相片上傳前請確保仍有本地備份。\n")
            DispatchQueue.global(qos: .utility).async {
                let handle = pipe.fileHandleForReading
                while true {
                    let data = handle.availableData
                    if data.isEmpty { break }
                    self.append(String(data: data, encoding: .utf8) ?? "")
                }
            }
        } catch {
            append("啟動失敗：" + error.localizedDescription + "\n")
        }
    }

    @objc private func stopUpload() {
        watcher?.terminate()
        // The shell script manages its own worker processes. Ask it to stop them, too.
        command("stop")
        updateState("停止中")
    }
    @objc private func showReport() { command("report") }
    @objc private func showLogs() { command("logs") }
    @objc private func verify() { command("verify") }

    @objc private func chooseFolder() {
        let picker = NSOpenPanel()
        picker.canChooseDirectories = true
        picker.canChooseFiles = false
        picker.allowsMultipleSelection = false
        picker.message = "選擇只用作上傳嘅資料夾（其他資料夾不會掃描）"
        if picker.runModal() == .OK, let url = picker.url {
            do {
                try (url.path + "\n").write(to: watchFile, atomically: true, encoding: .utf8)
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: watchFile.path)
                append("已指定資料夾：" + url.path + "\n")
                if watcher != nil { append("請停止並重新開始監察，以套用新資料夾。\n") }
            } catch { append("無法儲存設定：" + error.localizedDescription + "\n") }
        }
    }
    @objc private func openFolder() {
        let path = (try? String(contentsOf: watchFile, encoding: .utf8))?
            .split(separator: "\n").first.map(String.init) ?? photoFolder.path
        NSWorkspace.shared.open(URL(fileURLWithPath: path, isDirectory: true))
    }
    @objc private func openPhotos() {
        NSWorkspace.shared.open(URL(string: "https://photos.google.com/")!)
    }
    @objc private func quitApp() {
        if watcher != nil {
            let alert = NSAlert()
            alert.messageText = "上傳監察仍在運行"
            alert.informativeText = "請先按「停止」，確認上傳程序結束後再退出。"
            alert.runModal()
            return
        }
        NSApp.terminate(nil)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
