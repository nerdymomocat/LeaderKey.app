import SwiftUI

enum OptionsDisplayMode: String, CaseIterable {
    case never = "Never show"
    case afterDelay = "After delay"
    case always = "Always show"
}

final class UserState: ObservableObject {
  var userConfig: UserConfig!

  @Published var display: String?
  @Published var currentGroup: Group?
  @Published var showOptions = true
  @Published var optionsDisplayMode: OptionsDisplayMode = .afterDelay
  private var showOptionsTimer: Timer?

  init(userConfig: UserConfig!, lastChar: String? = nil, currentGroup: Group? = nil) {
    self.userConfig = userConfig
    display = lastChar
    self.currentGroup = currentGroup
    self.showOptions = false  // Start with options hidden
    updateOptionsVisibility()
  }

  func hideOptions() {
    guard optionsDisplayMode == .afterDelay else { return }
    showOptions = false
    showOptionsTimer?.invalidate()
    showOptionsTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
      self?.showOptions = true
    }
  }

  func updateOptionsVisibility() {
    switch optionsDisplayMode {
    case .never:
      showOptions = false
      showOptionsTimer?.invalidate()
    case .always:
      showOptions = true
      showOptionsTimer?.invalidate()
    case .afterDelay:
      showOptions = true
    }
  }

  func clear() {
    display = nil
    currentGroup = userConfig.root
    updateOptionsVisibility()
    showOptionsTimer?.invalidate()
  }
}
