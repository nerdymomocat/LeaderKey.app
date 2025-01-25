import KeyboardShortcuts
import LaunchAtLogin
import Settings
import SwiftUI

struct GeneralPane: View {
  private let contentWidth = 600.0
  @EnvironmentObject private var config: UserConfig
  @EnvironmentObject private var userState: UserState

  var body: some View {
    Settings.Container(contentWidth: contentWidth) {
      Settings.Section(
        title: "Config", bottomDivider: true, verticalAlignment: .top
      ) {
        VStack(alignment: .leading) {
          VStack {
            ConfigEditorView(group: $config.root)
              .frame(height: 400)
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

      Settings.Section(title: "Cheatsheet") {
        HStack {
          
          Picker("Config Display Mode", selection: $userState.optionsDisplayMode) { // Added label parameter
            ForEach(OptionsDisplayMode.allCases, id: \.self) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .frame(width: 129)
          .labelsHidden() // Hide the label since we're using our own Text view
          .onChange(of: userState.optionsDisplayMode) { _ in
            userState.updateOptionsVisibility()
          }
                  }
      }

      Settings.Section(title: "Shortcut") {
        KeyboardShortcuts.Recorder(for: .activate)
      }

      Settings.Section(title: "App") {
        LaunchAtLogin.Toggle()
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
