import SwiftUI

/// macOS 扫码登录：显示二维码，手机 App 扫码确认后自动登录
struct MacQRLoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var sessionId: String?
    @State private var deliveryKey: String?
    @State private var qrImage: NSImage?
    @State private var statusText = "正在获取二维码…"
    @State private var remaining = 180
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var statusTask: Task<Void, Error>?
    @State private var pollTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 20) {
            Text("扫码登录")
                .font(.title2)
                .fontWeight(.semibold)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(width: 244, height: 244)

                if let qrImage {
                    Image(nsImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 220, height: 220)
                } else if isLoading {
                    ProgressView()
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(20)
                }
            }

            Text(statusText)
                .font(.callout)
                .foregroundStyle(.secondary)

            if isLoading == false && errorMessage == nil {
                Text("二维码 \(remaining) 秒后失效")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            HStack(spacing: 12) {
                Button("刷新二维码") {
                    Task { await createSession() }
                }
                .disabled(isLoading)

                Button("使用账号密码") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(36)
        .frame(minWidth: 520, minHeight: 460)
        .task { await createSession() }
        .onDisappear { pollTask?.cancel() }
    }

    // MARK: - 会话与状态

    private func createSession() async {
        pollTask?.cancel()
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            statusText = "正在获取二维码…"
            qrImage = nil
            remaining = 180
        }

        do {
            let raw = try await NetworkService.shared.rawPost(url: APIConfig.qrCreateURL(), json: [:], token: nil)
            guard let json = try? JSONSerialization.jsonObject(with: raw) as? [String: Any],
                  let success = json["success"] as? Bool, success,
                  let data = json["data"] as? [String: Any],
                  let sid = data["sessionId"] as? String,
                  let key = data["deliveryKey"] as? String else {
                await MainActor.run {
                    errorMessage = "获取二维码失败"
                    isLoading = false
                }
                return
            }

            var image: NSImage?
            if let dataURL = data["qrImage"] as? String,
               let comma = dataURL.firstIndex(of: ",") {
                let base64 = String(dataURL[dataURL.index(after: comma)...])
                if let imageData = Data(base64Encoded: base64) {
                    image = NSImage(data: imageData)
                }
            }

            await MainActor.run {
                self.sessionId = sid
                self.deliveryKey = key
                self.qrImage = image
                self.isLoading = false
                self.statusText = "等待手机扫描…"
            }

            startCountdown()
            startStatusStream(sessionId: sid)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func startCountdown() {
        pollTask?.cancel()
        pollTask = Task {
            for _ in 0..<180 {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    self.remaining = max(0, self.remaining - 1)
                    if self.remaining == 0 {
                        self.statusText = "二维码已过期，请刷新"
                    }
                }
            }
        }
    }

    private func startStatusStream(sessionId: String) {
        Task {
            guard let url = URL(string: APIConfig.qrStatusURL(sessionId: sessionId)) else { return }
            var request = URLRequest(url: url)
            request.timeoutInterval = 240
            for (k, v) in APIConfig.clientHeaders {
                request.setValue(v, forHTTPHeaderField: k)
            }

            do {
                let (bytes, _) = try await URLSession.shared.bytes(for: request)
                for try await line in bytes.lines {
                    guard line.hasPrefix("data:") else { continue }
                    let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    guard let data = payload.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let status = json["status"] as? String else { continue }

                    switch status {
                    case "pending":
                        await MainActor.run { self.statusText = "等待手机扫描…" }
                    case "scanned":
                        await MainActor.run { self.statusText = "已扫描，请在手机上确认" }
                    case "confirmed":
                        await MainActor.run { self.statusText = "已确认，正在登录…" }
                        await claim()
                        return
                    case "canceled":
                        await MainActor.run { self.statusText = "已在手机上取消" }
                        return
                    case "expired":
                        await MainActor.run { self.statusText = "二维码已过期，请刷新" }
                        return
                    default:
                        break
                    }
                }
            } catch {
                await MainActor.run { self.statusText = "状态连接中断" }
            }
        }
    }

    private func claim() async {
        guard let sid = sessionId, let key = deliveryKey else { return }
        do {
            let raw = try await NetworkService.shared.rawPost(
                url: APIConfig.qrClaimURL(),
                json: ["sessionId": sid, "deliveryKey": key],
                token: nil
            )
            guard let json = try? JSONSerialization.jsonObject(with: raw) as? [String: Any],
                  let success = json["success"] as? Bool, success,
                  let data = json["data"] as? [String: Any],
                  let token = data["token"] as? String else {
                await MainActor.run { self.statusText = "领取登录令牌失败" }
                return
            }

            await MainActor.run {
                authService.applyRemoteSession(token: token, userJSON: data["user"] as? [String: Any] ?? [:])
                self.statusText = "登录成功"
                dismiss()
            }
        } catch {
            await MainActor.run { self.statusText = "登录失败：\(error.localizedDescription)" }
        }
    }
}
