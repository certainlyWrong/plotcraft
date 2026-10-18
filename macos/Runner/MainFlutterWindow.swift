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

    let fontsChannel = FlutterMethodChannel(
      name: "plotcraft/fonts",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    fontsChannel.setMethodCallHandler { call, result in
      guard call.method == "families" else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Families the person can pick; names starting with a dot are internal.
      result(NSFontManager.shared.availableFontFamilies.filter { !$0.hasPrefix(".") })
    }

    let spellCheckChannel = FlutterMethodChannel(
      name: "plotcraft/spell_check",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    spellCheckChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "checkRanges":
        // Asynchronous check of a whole text; only misspelled ranges (UTF-16
        // offsets, like Dart strings) are returned. Suggestions are fetched
        // on demand with "suggest" because they cost about 15 ms per word.
        guard let arguments = call.arguments as? [String: Any],
              let text = arguments["text"] as? String else {
          result(FlutterError(code: "invalid_argument", message: "Expected text", details: nil))
          return
        }
        let checker = NSSpellChecker.shared
        let language = MainFlutterWindow.spellLanguage(arguments["locale"] as? String ?? "", checker)
        // With automatic identification the requested language is ignored.
        checker.automaticallyIdentifiesLanguages = false
        checker.setLanguage(language)
        let length = (text as NSString).length
        if length == 0 {
          result([])
          return
        }
        checker.requestChecking(
          of: text,
          range: NSRange(location: 0, length: length),
          types: NSTextCheckingResult.CheckingType.spelling.rawValue,
          options: nil,
          inSpellDocumentWithTag: 0
        ) { _, results, _, _ in
          result(results.filter { $0.resultType == .spelling }.map {
            ["start": $0.range.location, "end": NSMaxRange($0.range)]
          })
        }
        return
      case "suggest":
        guard let arguments = call.arguments as? [String: Any],
              let word = arguments["word"] as? String else {
          result(FlutterError(code: "invalid_argument", message: "Expected word", details: nil))
          return
        }
        let checker = NSSpellChecker.shared
        let language = MainFlutterWindow.spellLanguage(arguments["locale"] as? String ?? "", checker)
        let guesses = checker.guesses(
          forWordRange: NSRange(location: 0, length: (word as NSString).length),
          in: word,
          language: language,
          inSpellDocumentWithTag: 0
        ) ?? []
        result(Array(guesses.prefix(6)))
        return
      case "learn":
        if let word = (call.arguments as? [String: Any])?["word"] as? String {
          NSSpellChecker.shared.learnWord(word)
        }
        result(nil)
        return
      default:
        break
      }
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

  /// Picks the installed spelling language that best matches a locale tag
  /// such as "pt-BR" or "en".
  private static func spellLanguage(_ requested: String, _ checker: NSSpellChecker) -> String {
    let wanted = requested.replacingOccurrences(of: "-", with: "_")
    return checker.availableLanguages.first {
      $0.caseInsensitiveCompare(wanted) == .orderedSame
    } ?? checker.availableLanguages.first {
      $0.lowercased().hasPrefix(wanted.lowercased() + "_")
    } ?? checker.language()
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
