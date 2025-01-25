//
//  MainView.swift
//  Leader Key
//
//  Created by Mikkel Malmberg on 19/04/2024.
//

import SwiftUI

struct MainView: View {
  @EnvironmentObject var userState: UserState
  
  func truncatedValue(_ value: String) -> String {
    if value.count <= 20 { return value }
    let prefix = String(value.prefix(10))
    let suffix = String(value.suffix(10))
    return "\(prefix)...\(suffix)"
  }
  
  var currentOptions: [(key: String, displayText: String?, fullValue: String?)] {
    let actions = (userState.currentGroup ?? userState.userConfig.root).actions
    return actions.compactMap { item -> (String, String?, String?)? in
      switch item {
      case .action(let action):
        if action.friendly.isEmpty {
          return (action.key, truncatedValue(action.value), action.value)
        } else {
          return (action.key, action.friendly, nil)
        }
      case .group(let group):
        // Show friendly name for groups if it exists
        if let friendly = group.friendly, !friendly.isEmpty {
          return (group.key ?? "", friendly, nil)
        }
        return (group.key ?? "", nil, nil)
      }
    }
  }

  // Pre-compute options view
  private var optionsView: some View {
    VStack(alignment: .leading, spacing: 4) {
      ForEach(currentOptions, id: \.key) { option in
        HStack(spacing: 4) {
          Text(option.key)
            .fontWeight(.medium)
          if let displayText = option.displayText {
            Text("→")
              .foregroundColor(.secondary)
            Text(displayText)
              .foregroundColor(.secondary)
          }
        }
        .font(.system(size: 14, design: .rounded))
      }
    }
    .padding(.top, 8)
  }

  var body: some View {
    VStack(spacing: 8) {
      // Main symbol/key display
      Text(userState.currentGroup?.key ?? userState.display ?? "●")
        .fontDesign(.rounded)
        .fontWeight(.semibold)
        .font(.system(size: 28, weight: .semibold, design: .rounded))
      
      if let friendly = userState.currentGroup?.friendly, !friendly.isEmpty {
        Text("(\(friendly))")
          .fontDesign(.rounded)
          .fontWeight(.regular)
          .font(.system(size: 16))
          .foregroundColor(.secondary)
      }
      
      if userState.showOptions {
        optionsView
      }
    }
    .frame(width: 250)
    .frame(minHeight: 250)  // Set minimum height
    .background(
      GeometryReader { proxy in
        VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
          .frame(height: proxy.size.height)
      }
    )
    .clipShape(RoundedRectangle(cornerRadius: 25.0, style: .continuous))
  }
}

struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    MainView().environmentObject(UserState(userConfig: UserConfig()))
  }
}
