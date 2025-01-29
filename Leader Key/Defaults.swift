import Defaults

let CONFIG_DIR_EMPTY = "CONFIG_DIR_EMPTY"

extension Defaults.Keys {
  static let watchConfigFile = Key<Bool>("watchConfigFile", default: false)
  static let configDir = Key<String>("configDir", default: CONFIG_DIR_EMPTY)
  static let showMenuBarIcon = Key<Bool>("showInMenubar", default: true)
  static let cheatsheetBehavior = Key<CheatsheetBehavior>("cheatsheetBehavior", default: .onQuestionMark)
  static let cheatsheetDelay = Key<Double>("cheatsheetDelay", default: 1) // in seconds
}

enum CheatsheetBehavior: String, Codable, CaseIterable, Defaults.Serializable {
  case never = "Never"
  case onQuestionMark = "On ? key"
  case always = "Always" 
  case afterDelay = "After delay"
}
