import SwiftUI

final class UserState: ObservableObject {
  var userConfig: UserConfig!

  @Published var display: String?
  @Published var currentGroup: Group?
  @Published var showOptions = true
  private var showOptionsTimer: Timer?

  init(userConfig: UserConfig!, lastChar: String? = nil, currentGroup: Group? = nil) {
    self.userConfig = userConfig
    display = lastChar
    self.currentGroup = currentGroup
    self.showOptions = false  // Start with options hidden
  }

  func hideOptions() {
    showOptions = false
    showOptionsTimer?.invalidate()
    showOptionsTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
      self?.showOptions = true
    }
  }

  func clear() {
    display = nil
    currentGroup = userConfig.root
    showOptions = true
    showOptionsTimer?.invalidate()
  }
}
