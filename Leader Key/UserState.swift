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
  private var groupHistory: [Group] = []  // Add this line

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

  func pushGroup(_ group: Group) {
    if let currentGroup = currentGroup {
      groupHistory.append(currentGroup)
    }
    currentGroup = group
    display = group.key
  }

  func popGroup() -> Bool {
    guard !groupHistory.isEmpty else {
      return false  // At root level
    }
    currentGroup = groupHistory.removeLast()
    display = currentGroup?.key
    return true
  }

  func clear() {
    display = nil
    currentGroup = nil
    groupHistory.removeAll()
    updateOptionsVisibility()
    showOptionsTimer?.invalidate()
  }
}
