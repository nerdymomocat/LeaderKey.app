import KeyboardShortcuts
import LaunchAtLogin
import Settings
import SwiftUI
import Defaults

struct GeneralPane: View {
  private let contentWidth = 680.0
  @EnvironmentObject private var config: UserConfig
  @Default(.cheatsheetBehavior) private var cheatsheetBehavior
  @Default(.cheatsheetDelay) private var cheatsheetDelay

  var body: some View {
    Settings.Container(contentWidth: contentWidth) {
      Settings.Section(
        title: "Config", bottomDivider: true, verticalAlignment: .top
      ) {
        VStack(alignment: .leading) {
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

            Button("Reveal config file in Finder") {
              NSWorkspace.shared.activateFileViewerSelecting([config.fileURL()])
            }
          }
        }
      }

      Settings.Section(title: "Shortcut") {
        KeyboardShortcuts.Recorder(for: .activate)
      }

      Settings.Section(title: "App") {
        LaunchAtLogin.Toggle()
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
