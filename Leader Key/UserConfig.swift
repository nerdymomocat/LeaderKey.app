import Cocoa
import Combine
import Defaults

class UserConfig: ObservableObject {
  @Published var root = Group(actions: [])

  let fileName = "config.json"
  let fileMonitor = FileMonitor()

  var afterReload: ((_ success: Bool) -> Void)?

  func fileURL() -> URL {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[0].appendingPathComponent(fileName)
  }

  func configExists() -> Bool {
    FileManager.default.fileExists(atPath: fileURL().path())
  }

  func bootstrapConfig() throws {
    print("Writing default config")
    let data = defaultConfig.data(using: .utf8)
    try data?.write(to: fileURL())
  }

  func readConfigFile() -> String {
    do {
      let str = try String(contentsOfFile: fileURL().path(), encoding: .utf8)
      return str
    } catch {
      print("Error decoding JSON: \(error)")
      let alert = NSAlert()
      alert.alertStyle = .critical
      alert.messageText = "\(error)"
      alert.runModal()
      return "{}"
    }
  }

  func loadAndWatch() {
    if !configExists() {
      do {
        try bootstrapConfig()
      } catch {
        print("Failed writing default config: \(error)")
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "\(error)"
        alert.runModal()
        root = Group(actions: [])
      }
    }

    loadConfig()
    startWatching()
  }

  private func startWatching() {
    self.fileMonitor.startMonitoring(fileURL: fileURL()) {
      print("File has been modified.")
      self.reloadConfig()
    }
  }

  func loadConfig() {
    if FileManager.default.fileExists(atPath: fileURL().path) {
      if let jsonData = readConfigFile().data(using: .utf8) {
        let decoder = JSONDecoder()
        do {
          let root_ = try decoder.decode(Group.self, from: jsonData)
          root = root_
        } catch {
          print("Error decoding JSON: \(error)")
          handleConfigError(error)
        }
      } else {
        print("Failed to read config file")
        root = Group(actions: [])
      }
    } else {
      print("Config file does not exist, using empty configuration")
      root = Group(actions: [])
    }
  }

  private func handleConfigError(_ error: Error) {
    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = "\(error)"
    alert.runModal()
    root = Group(actions: [])
  }

  func reloadConfig() {
    loadConfig()
    afterReload?(true)
  }

  func saveConfig() {
    // Stop monitoring temporarily
    fileMonitor.stopMonitoring()

    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
      let jsonData = try encoder.encode(root)
      try jsonData.write(to: fileURL())
    } catch {
      print("Error saving config: \(error)")
      handleConfigError(error)
    }

    // Resume monitoring
    reloadConfig()
    startWatching()
  }
}

let defaultConfig = """
  {
      "type": "group",
      "actions": [
          { "key": "t", "type": "application", "value": "/System/Applications/Utilities/Terminal.app", "friendly":"Terminal" },
          {
              "key": "o",
              "type": "group",
              "friendly":"Operating System",
              "actions": [
                  { "key": "s", "type": "application", "value": "/Applications/Safari.app", "friendly":"Safari" },
                  { "key": "e", "type": "application", "value": "/Applications/Mail.app", "friendly":"Mail" },
                  { "key": "i", "type": "application", "value": "/System/Applications/Music.app", "friendly":"Music" },
                  { "key": "m", "type": "application", "value": "/Applications/Messages.app", "friendly":"Apple Messages" }
              ]
          },
          {
              "key": "r",
              "type": "group",
              "friendly":"Raycast",
              "actions": [
                  { "key": "e", "type": "url", "value": "raycast://extensions/raycast/emoji-symbols/search-emoji-symbols", "friendly": "Emoji" },
                  { "key": "p", "type": "url", "value": "raycast://confetti", "friendly": "confetti" },
                  { "key": "c", "type": "url", "value": "raycast://extensions/raycast/system/open-camera", "friendly": "camera" }
              ]
          }
      ]
  }
  """

enum Type: String, Codable {
  case group
  case application
  case url
  case command
}

struct Action: Codable {
  var key: String
  var type: Type
  var value: String
  var friendly: String
}

struct Group: Codable {
  var key: String?
  var friendly: String?
  var type: Type = .group
  var actions: [ActionOrGroup]
}

enum ActionOrGroup: Codable {
  case action(Action)
  case group(Group)

  private enum CodingKeys: String, CodingKey {
    case key, type, value, actions, friendly
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let key = try container.decode(String.self, forKey: .key)
    let type = try container.decode(Type.self, forKey: .type)
    switch type {
    case .group:
      let actions = try container.decode([ActionOrGroup].self, forKey: .actions)
      let friendly = try container.decodeIfPresent(String.self, forKey: .friendly) ?? "" // Default to empty string
      self = .group(Group(key: key, friendly: friendly, actions: actions))
    default:
      let value = try container.decode(String.self, forKey: .value)
      let friendly = try container.decodeIfPresent(String.self, forKey: .friendly) ?? "" // Default to empty string
      self = .action(Action(key: key, type: type, value: value, friendly: friendly))
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .action(action):
      try container.encode(action.key, forKey: .key)
      try container.encode(action.type, forKey: .type)
      try container.encode(action.value, forKey: .value)
      try container.encode(action.friendly, forKey: .friendly)
    case let .group(group):
      try container.encode(group.key, forKey: .key)
      try container.encode(Type.group, forKey: .type)
      try container.encode(group.actions, forKey: .actions)
      try container.encodeIfPresent(group.friendly, forKey: .friendly)
    }
  }
}
