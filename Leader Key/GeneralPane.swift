import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import Settings
import SwiftUI
import Defaults

struct GeneralPane: View {
  private let contentWidth = 720.0
  @EnvironmentObject private var config: UserConfig
  @Default(.configDir) var configDir
  @Default(.cheatsheetBehavior) private var cheatsheetBehavior
  @Default(.cheatsheetDelay) private var cheatsheetDelay

  var body: some View {
    Settings.Container(contentWidth: contentWidth) {
      Settings.Section(
        title: "Config", bottomDivider: true, verticalAlignment: .top
      ) {
        VStack(alignment: .leading, spacing: 8) {
          VStack {
            ConfigEditorView(group: $config.root)
              .frame(height: 500)
          }
          .padding(8)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .inset(by: 1)
              .stroke(Color.primary, lineWidth: 1)
              .opacity(0.1)
          )

          HStack {
            Button("Save to file") {
              config.saveConfig()
            }

            Button("Reload from file") {
              config.reloadConfig()
            }
          }
        }
      }

      Settings.Section(title: "Directory", bottomDivider: true) {
        HStack {
          Button("Choose…") {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            if panel.runModal() != .OK { return }
            guard let selectedPath = panel.url else { return }
            configDir = selectedPath.path
          }

          Text(configDir).lineLimit(1).truncationMode(.middle)

          Spacer()

          Button("Reveal") {
            NSWorkspace.shared.activateFileViewerSelecting([
              config.fileURL()
            ])
          }

          Button("Reset") {
            configDir = UserConfig.defaultDirectory()
          }
        }
      }

      Settings.Section(title: "Shortcut") {
        KeyboardShortcuts.Recorder(for: .activate)
      }

      Settings.Section(title: "App") {
        LaunchAtLogin.Toggle()
        Defaults.Toggle("Show Leader Key in menubar", key: .showMenuBarIcon)
      }

      Settings.Section(title: "Cheatsheet") {
        HStack(alignment: .firstTextBaseline) {  // Weird setup here to get labels to align to text
          Text("Show:")
          Picker("", selection: $cheatsheetBehavior) {
            ForEach(CheatsheetBehavior.allCases, id: \.self) { behavior in
              Text(behavior.rawValue).tag(behavior)
            }
          }
          .labelsHidden()
          .frame(width: 200)
          
          if cheatsheetBehavior == .afterDelay {
            Text("Delay:")
              .padding(.leading, 16)
            TextField("", value: $cheatsheetDelay, formatter: NumberFormatter())
              .frame(width: 30)
            Text("seconds")
          }
          
          Spacer()
        }
      }
    }
  }
}

struct GeneralPane_Previews: PreviewProvider {
  static var previews: some View {
    return GeneralPane()
      .environmentObject(UserConfig())
  }
}
