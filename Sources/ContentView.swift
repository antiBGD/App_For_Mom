import SwiftUI

struct ContentView: View {
    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var accounts: [SavedAccount] = AccountStore.load()
    @State private var showLogin = true
    @State private var reloadToken = 0
    @State private var activeUser = ""
    @State private var activePass = ""
    @State private var rainbowIndex = 0

    private let siteURL = URL(string: "http://113.160.96.94:8088/")!
    private let darkRed = Color(red: 0.5, green: 0.0, blue: 0.08)
    private let rainbow: [Color] = [
        .red, .orange, .yellow, .green, .blue,
        Color(red: 0.29, green: 0.0, blue: 0.51), .purple
    ]
    private let ticker = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    private var canSave: Bool { !name.isEmpty && !username.isEmpty && !password.isEmpty }
    private var canEnter: Bool { !username.isEmpty && !password.isEmpty }

    var body: some View {
        if showLogin {
            loginView
        } else {
            webScreen
        }
    }

    private var webScreen: some View {
        ZStack(alignment: .topTrailing) {
            WebView(url: siteURL, username: activeUser, password: activePass, reloadToken: reloadToken)
                .ignoresSafeArea(edges: .bottom)

            Menu {
                Button("Tải lại và đăng nhập") { reloadToken += 1 }
                Button("Đổi tài khoản") { showLogin = true }
            } label: {
                Image(systemName: "gearshape.fill")
                    .padding(10)
                    .background(Circle().fill(Color.gray.opacity(0.35)))
                    .padding(.trailing, 12)
            }
        }
    }

    private var loginView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("ĐĂNG NHẬP")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(darkRed)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)
                    .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tên :").font(.system(size: 18, weight: .bold))
                    TextField("", text: $name)
                        .disableAutocorrection(true)
                    Rectangle().fill(Color.black).frame(height: 2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tài Khoản :").font(.system(size: 18, weight: .bold))
                    TextField("", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Rectangle().fill(Color.black).frame(height: 2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Mật Khẩu :").font(.system(size: 18, weight: .bold))
                    SecureField("", text: $password)
                    Rectangle().fill(Color.black).frame(height: 2)
                }

                HStack(spacing: 24) {
                    Button(action: saveAccount) { outlinedLabel("Lưu") }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.45)
                    Button(action: enter) { outlinedLabel("Vào") }
                        .disabled(!canEnter)
                        .opacity(canEnter ? 1 : 0.45)
                }

                savedList

                Text("Developer : datpahm")
                    .font(.system(size: 14, weight: .bold))
                    .underline()
                    .foregroundColor(rainbow[rainbowIndex])
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .onReceive(ticker) { _ in
                        rainbowIndex = (rainbowIndex + 1) % rainbow.count
                    }
            }
            .padding(.horizontal, 22)
            .foregroundColor(.black)
        }
        .background(Color.white.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    private func outlinedLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
    }

    private var savedList: some View {
        VStack(spacing: 0) {
            Text("Danh Sách Lưu")
                .font(.system(size: 15, weight: .bold))
                .underline()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            Rectangle().fill(Color.black).frame(height: 2)

            if accounts.isEmpty {
                Text("Chưa có tài khoản nào được lưu")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(16)
            }

            ForEach(accounts) { acc in
                HStack {
                    Button(action: {
                        name = acc.name
                        username = acc.username
                        password = acc.password
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(acc.name)
                                .font(.system(size: 16, weight: .bold))
                                .underline()
                                .foregroundColor(.black)
                            Text(acc.username)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button(action: { delete(acc) }) {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                }
                .padding(12)
                Rectangle().fill(Color.black).frame(height: 2)
            }
        }
        .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
    }

    private func saveAccount() {
        let n = name.trimmingCharacters(in: .whitespaces)
        let u = username.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, !u.isEmpty, !password.isEmpty else { return }
        let acc = SavedAccount(name: n, username: u, password: password)
        if let i = accounts.firstIndex(where: { $0.name == n }) {
            accounts[i] = acc
        } else {
            accounts.append(acc)
        }
        AccountStore.save(accounts)
    }

    private func delete(_ acc: SavedAccount) {
        accounts.removeAll { $0.id == acc.id }
        AccountStore.save(accounts)
    }

    private func enter() {
        guard canEnter else { return }
        activeUser = username
        activePass = password
        showLogin = false
        reloadToken += 1
    }
}