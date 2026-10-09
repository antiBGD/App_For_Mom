import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var unlocked = false
    @State private var showSettings = false
    @State private var reloadToken = 0

    private let siteURL = URL(string: "http://113.160.96.94:8088/")!

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if unlocked {
                WebView(url: siteURL, username: username, password: password, reloadToken: reloadToken)
                    .ignoresSafeArea(edges: .bottom)

                Menu {
                    Button("Tải lại và đăng nhập") { reloadToken += 1 }
                    Button("Tài khoản đã lưu") { showSettings = true }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(.trailing, 12)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill").font(.system(size: 48))
                    Button("Mở khóa") { authenticate() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showSettings) { settingsView }
        .onAppear {
            username = Keychain.load("user") ?? ""
            password = Keychain.load("pass") ?? ""
            if username.isEmpty {
                unlocked = true
                showSettings = true
            } else {
                authenticate()
            }
        }
    }

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("Tài khoản VNHR") {
                    TextField("ID tập đoàn hoặc mã nhân viên", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Mật khẩu", text: $password)
                }
            }
            .navigationTitle("Đăng nhập nhanh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        Keychain.save(username, for: "user")
                        Keychain.save(password, for: "pass")
                        showSettings = false
                        reloadToken += 1
                    }
                }
            }
        }
    }

    private func authenticate() {
        let ctx = LAContext()
        var error: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            ctx.evaluatePolicy(.deviceOwnerAuthentication,
                               localizedReason: "Mở khóa đăng nhập nhanh") { ok, _ in
                DispatchQueue.main.async { unlocked = ok }
            }
        } else {
            unlocked = true
        }
    }
}