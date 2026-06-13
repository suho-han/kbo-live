import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TodayGamesViewModel

    var body: some View {
        Form {
            Picker("응원팀", selection: Binding(
                get: { viewModel.selectedTeamID ?? "" },
                set: { newValue in
                    viewModel.selectTeam(newValue.isEmpty ? nil : newValue)
                }
            )) {
                Text("선택 안 함").tag("")
                ForEach(viewModel.allTeams) { team in
                    Text(team.name).tag(team.id)
                }
            }
            .pickerStyle(.menu)
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 320)
    }
}
