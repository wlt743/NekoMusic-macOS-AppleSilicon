import SwiftUI

/// macOS 登录界面
struct MacLoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var showQRLogin = false

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                Text("登录 NekoMusic")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 12) {
                TextField("邮箱", text: $email)
                    .textFieldStyle(.roundedBorder)

                SecureField("密码", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await login() } }
            }
            .frame(maxWidth: 320)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            Button {
                Task { await login() }
            } label: {
                HStack {
                    if isWorking { ProgressView().controlSize(.small) }
                    Text(isWorking ? "登录中…" : "登录")
                }
                .frame(maxWidth: 320)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isWorking || email.isEmpty || password.isEmpty)

            Button {
                showQRLogin = true
            } label: {
                Label("扫码登录（用手机确认）", systemImage: "qrcode")
                    .frame(maxWidth: 320)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Text("登录后才能使用收藏、歌单同步等功能")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 420)
        .sheet(isPresented: $showQRLogin) {
            MacQRLoginView()
                .environmentObject(authService)
        }
    }

    private func login() async {
        guard !email.isEmpty, !password.isEmpty else { return }
        isWorking = true
        errorMessage = nil
        defer { Task { @MainActor in isWorking = false } }

        do {
            let response = try await authService.login(email: email, password: password)
            await MainActor.run {
                if response.success {
                    dismiss()
                } else {
                    errorMessage = response.message ?? "登录失败"
                }
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
}
