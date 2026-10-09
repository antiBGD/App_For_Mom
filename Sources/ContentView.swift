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
            password =