import Cocoa
import Combine

enum KeyHelpers: UInt16 {
  case Return = 36
  case Tab = 48
  case Space = 49
  case Backspace = 51
  case Escape = 53
}

class Controller {
  var window: Window!
  var userState: UserState
  var userConfig: UserConfig

  var focusCancellable: AnyCancellable?

  var subjectInputCancellable: AnyCancellable?
  var subjectCancellable: AnyCancellable?

  var actionInputCancellable: AnyCancellable?

  init(userState: UserState, userConfig: UserConfig) {
    self.userState = userState
    self.userConfig = userConfig
  }

  func show() {
    window.show()
  }

  func hide() {
    window.hide {
      self.clear()
    }
  }

  func keyDown(with event: NSEvent) {
    switch event.keyCode {
    case KeyHelpers.Backspace.rawValue:
      if !userState.popGroup() {
        // At root level, only clear if we have a display value
        if userState.display != nil {
          clear()
        }
      }
      userState.hideOptions()
    case KeyHelpers.Escape.rawValue:
      hide()
    default:
      let char = event.charactersIgnoringModifiers?.lowercased()

      let list = (userState.currentGroup != nil) ? userState.currentGroup : userConfig.root

      let hit = list?.actions.first { item in
        switch item {
        case let .group(group):
          if group.key?.lowercased() == char {
            return true
          }
        case let .action(action):
          if action.key.lowercased() == char {
            return true
          }
        }
        return false
      }

      switch hit {
      case let .action(action):
        userState.hideOptions()
        runAction(action)
        hide()
      case let .group(group):
        userState.hideOptions()
        userState.pushGroup(group)  // Changed from direct assignment to pushGroup
      case .none:
        window.shake()
        userState.showOptions = true
      }
    }
  }

  private func runAction(_ action: Action) {
    switch action.type {
    case .application:
      NSWorkspace.shared.openApplication(
        at: URL(fileURLWithPath: action.value), configuration: NSWorkspace.OpenConfiguration())
    case .url:
      NSWorkspace.shared.open(
        URL(string: action.value)!, configuration: DontActivateConfiguration.shared.configuration)
    case .command:
      CommandRunner.run(action.value)
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
