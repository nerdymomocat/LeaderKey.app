import Cocoa
import Combine
import SwiftUI
import Defaults

enum KeyHelpers: UInt16 {
  case Return = 36
  case Tab = 48
  case Space = 49
  case Backspace = 51
  case Escape = 53
}

class Controller {
  var userState: UserState
  var userConfig: UserConfig

  var window: Window!
  var cheatsheetWindow: NSWindow?
  private var cheatsheetTimer: Timer?

  init(userState: UserState, userConfig: UserConfig) {
    self.userState = userState
    self.userConfig = userConfig
    self.cheatsheetWindow = Cheatsheet.createWindow(for: userState)
  }

  func show() {
    window.show()
    
    // Handle cheatsheet display based on preferences
    switch Defaults[.cheatsheetBehavior] {
    case .always:
      showCheatsheet()
    case .afterDelay:
      // Start the initial delay timer when window opens
      scheduleCheatsheet()
    default:
      break
    }
  }

  func hide() {
    window.hide {
      self.clear()
    }
    hideCheatsheet()
  }

  func keyDown(with event: NSEvent) {
    // Reset/start the delay timer on any key press if we're in afterDelay mode
    if Defaults[.cheatsheetBehavior] == .afterDelay {
      scheduleCheatsheet()
    }

    if event.modifierFlags.contains(.command) {
      switch event.charactersIgnoringModifiers {
      case ",":
        NSApp.sendAction(
          #selector(AppDelegate.settingsMenuItemActionHandler(_:)), to: nil,
          from: nil)
        hide()
        return
      case "w":
        hide()
        return
      case "q":
        NSApp.terminate(nil)
        return
      default:
        break
      }
    }

    switch event.keyCode {
    case KeyHelpers.Backspace.rawValue:
      clear()
    case KeyHelpers.Escape.rawValue:
      hide()
    default:
      let char = event.charactersIgnoringModifiers?.lowercased()

      if char == "?" {
        if Defaults[.cheatsheetBehavior] == .onQuestionMark {
          showCheatsheet()
        }
        return
      }

      let list =
        (userState.currentGroup != nil)
        ? userState.currentGroup : userConfig.root

      let hit = list?.actions.first { item in
        switch item {
        case let .group(group):
          if group.key?.lowercased() == char {
            return true
          }
        case let .action(action):
          if action.key?.lowercased() == char {
            return true
          }
        }
        return false
      }

      switch hit {
      case let .action(action):
        runAction(action)
        hide()
      case let .group(group):
        userState.display = group.key
        userState.currentGroup = group
      case .none:
        window.shake()
      }
    }

    // Why do we need to wait here?
    delay(1) {
      self.positionCheatsheetWindow()
    }
  }

  private func scheduleCheatsheet() {
    // Cancel any existing timer first
    hideCheatsheet()
    
    // Start a new timer
    cheatsheetTimer = Timer.scheduledTimer(withTimeInterval: Defaults[.cheatsheetDelay], repeats: false) { [weak self] _ in
      self?.showCheatsheet()
    }
  }

  private func hideCheatsheet() {
    cheatsheetTimer?.invalidate()
    cheatsheetTimer = nil
    cheatsheetWindow?.orderOut(nil)
  }

  private func positionCheatsheetWindow() {
    guard let mainWindow = window, let cheatsheet = cheatsheetWindow else {
      return
    }
    let frame = mainWindow.frame
    let point = NSPoint(
      x: frame.maxX + 20,
      y: frame.midY - cheatsheet.frame.height / 2
    )
    cheatsheet.setFrameOrigin(point)
  }

  private func showCheatsheet() {
    positionCheatsheetWindow()
    cheatsheetWindow?.orderFront(nil)
  }

  private func runAction(_ action: Action) {
    switch action.type {
    case .application:
      NSWorkspace.shared.openApplication(
        at: URL(fileURLWithPath: action.value),
        configuration: NSWorkspace.OpenConfiguration())
    case .url:
      NSWorkspace.shared.open(
        URL(string: action.value)!,
        configuration: DontActivateConfiguration.shared.configuration)
    case .command:
      CommandRunner.run(action.value)
    case .folder:
      NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: action.value)
    default:
      print("\(action.type) unknown")
    }
  }

  private func clear() {
    userState.clear()
  }
}

class DontActivateConfiguration {
  let configuration = NSWorkspace.OpenConfiguration()

  static var shared = DontActivateConfiguration()

  init() {
    configuration.activates = false
  }
}
