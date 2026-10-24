import SwiftUI

struct MacProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appearance: AppearanceSettings
    @State private var showLogin = false
    @State private var showSettings = false

    var body: some View {
        Form {
            Section("账户") {
                if let user = authService.currentUser {
                    LabeledContent("昵称", value: user.nickname)
                    LabeledContent("用户 ID", value: "\(user.id)")
                } else {
                    Button("登录") {
                        showLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("外观") {
                Button {
                    showSettings = true
                } label: {
                    Label("主题色与壁纸", systemImage: "paintpalette")
                }
            }

            Section("版本") {
                LabeledContent("版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("我的")
        .sheet(isPresented: $showLogin) {
            MacLoginView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                MacSettingsView()
            }
            .frame(minWidth: 560, minHeight: 520)
        }
    }
}
