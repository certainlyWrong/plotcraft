import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var activeProjectFolders: [URL] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let folderChannel = FlutterMethodChannel(
      name: "plotcraft/folder_access",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    folderChannel.setMethodCallHandler { [weak self] call, result in
      if call.method == "selectFolder" {
        self?.selectProjectFolder(initialPath: call.arguments as? String, result: result)
        return
      }
      guard let encodedPath = call.arguments as? String else {
        result(FlutterError(code: "invalid_argument", message: "Expected a folder path or bookmark", details: nil))
        return
      }
      do {
        switch call.method {
        case "activateBookmark":
          guard let data = Data(base64Encoded: encodedPath) else {
            result(FlutterError(code: "invalid_bookmark", message: "Invalid folder bookmark", details: nil))
            return
          }
          var isStale = false
          let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
          )
          guard url.startAccessingSecurityScopedResource() else {
            result(FlutterError(code: "folder_unavailable", message: "Folder access is unavailable", details: nil))
            return
          }
          self?.activeProjectFolders.append(url)
          result(url.path)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "folder_access_failed", message: error.localizedDescription, details: nil))
      }
    }

    let spellCheckChannel = FlutterMethodChannel(
      name: "plotcraft/spell_check",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    spellCheckChannel.setMethodCallHandler { call, result in
      guard call.method == "check",
            let arguments = call.arguments as? [String: Any],
            let text = arguments["text"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      let checker = NSSpellChecker.shared
      let requested = (arguments["locale"] as? String ?? "")
        .replacingOccurrences(of: "-", with: "_")
      let language = checker.availableLanguages.first {
        $0.caseInsensitiveCompare(requested) == .orderedSame
      } ?? checker.availableLanguages.first {
        $0.lowercased().hasPrefix(requested.lowercased() + "_")
      } ?? checker.language()
      let length = (text as NSString).length
      var offset = 0
      var matches: [[String: Any]] = []
      while offset < length && matches.count < 300 {
        let range = checker.checkSpelling(
          of: text,
          startingAt: offset,
          language: language,
          wrap: false,
          inSpellDocumentWithTag: 0,
          wordCount: nil
        )
        if range.location == NSNotFound || range.length == 0 { break }
        let suggestions = checker.guesses(
          forWordRange: range,
          in: text,
          language: language,
          inSpellDocumentWithTag: 0
        ) ?? []
        matches.append([
          "start": range.location,
          "end": NSMaxRange(range),
          "suggestions": Array(suggestions.prefix(5)),
        ])
        offset = NSMaxRange(range)
      }
      result(matches)
    }

    super.awakeFromNib()
  }

  private func selectProjectFolder(initialPath: String?, result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false

    if let initialPath = initialPath, !initialPath.isEmpty {
      var directory = URL(fileURLWithPath: initialPath, isDirectory: true)
      while !FileManager.default.fileExists(atPath: directory.path) {
        let parent = directory.deletingLastPathComponent()
        if parent.path == directory.path { break }
        directory = parent
      }
      if FileManager.default.fileExists(atPath: directory.path) {
        panel.directoryURL = directory
      }
    }

    panel.beginSheetModal(for: self) { [weak self] response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }
      do {
        // Keep the URL returned by NSOpenPanel. Rebuilding it from its path
        // loses the security scope needed to create a persistent bookmark.
        let bookmark = try url.bookmarkData(
          options: [.withSecurityScope],
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        )
        if url.startAccessingSecurityScopedResource() {
          self?.activeProjectFolders.append(url)
        }
        result(["path": url.path, "bookmark": bookmark.base64EncodedString()])
      } catch {
        result(FlutterError(code: "folder_access_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  deinit {
    for url in activeProjectFolders {
      url.stopAccessingSecurityScopedResource()
    }
  }
}
