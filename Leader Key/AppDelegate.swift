import Cocoa
import KeyboardShortcuts
import Settings
import Sparkle
import SwiftUI
import Combine

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var window: Window!
  var controller: Controller!

  let statusItem = StatusItem()
  let config = UserConfig()

  var state: UserState!
  @IBOutlet var updaterController: SPUStandardUpdaterController!

  lazy var settingsWindowController = SettingsWindowController(
    panes: [
      Settings.Pane(
        identifier: .general, title: "General",
        toolbarIcon: NSImage(named: NSImage.preferencesGeneralName)!,
        contentView: { GeneralPane().environmentObject(self.config) }
      )
    ]
  )

  private var observers = Set<AnyCancellable>()

  private func fixMenu() {
    let menu = NSMenu(title: "Edit")
    
    menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
    
    let editMenuItem = NSMenuItem()
    editMenuItem.title = "Edit"
    editMenuItem.submenu = menu
    if NSApp.mainMenu == nil {
        NSApp.mainMenu = NSMenu()
    }
    NSApp.mainMenu?.items = [editMenuItem]
  }

  func applicationDidFinishLaunching(_: Notification) {
    guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }

    state = UserState(userConfig: config)

    controller = Controller(userState: state, userConfig: config)
    window = Window(controller: controller)
    controller.window = window

    config.afterReload = { _ in
      self.state.display = "🔃"

      self.show()
      delay(1000) {
        self.hide()
      }
    }

    config.loadAndWatch()

    statusItem.handlePreferences = {
      self.settingsWindowController.show()
      NSApp.activate(ignoringOtherApps: true)
    }
    statusItem.handleReloadConfig = {
      self.config.reloadConfig()
    }
    statusItem.handleRevealConfig = {
      NSWorkspace.shared.activateFileViewerSelecting([self.config.fileURL()])
    }
    statusItem.handleCheckForUpdates = {
      self.updaterController.checkForUpdates(nil)
    }
    statusItem.enable()

    KeyboardShortcuts.onKeyUp(for: .activate) {
      if self.window.isVisible && self.window.isKeyWindow {
        self.hide()
      } else {
        self.state.hideOptions()  // Changed from userState to state
        self.show()
      }
    }

    NSApp.publisher(for: \.mainMenu)
        .sink { [weak self] _ in self?.fixMenu() }
        .store(in: &observers)
  }

  @IBAction
  func settingsMenuItemActionHandler(_: NSMenuItem) {
    self.settingsWindowController.show()
    NSApp.activate(ignoringOtherApps: true)
  }

  func show() {
    controller.show()
  }

  func hide() {
    controller.hide()
  }
}
