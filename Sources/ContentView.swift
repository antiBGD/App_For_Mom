import SwiftUI
import UIKit

struct ContentView: View {
    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var accounts: [SavedAccount] = AccountStore.load()
    @State private var showLogin = true
    @State private var reloadToken = 0
    @State private var activeUser = ""
    @State private var activePass = ""
    @State private var rainbowIndex = 0
    @State private var toast = ""

    private let siteURL = URL(string: "http://113.160.96.94:8088/")!
    private let brand = Color(red: 0.5, green: 0.0, blue: 0.08)
    private let fieldBg = Color(red: 0.95, green: 0.95, blue: 0.96)
    private let rainbow: [Color] = [
        .red, .orange, .yellow, .green, .blue,
        Color(red: 0.29, green: 0.0, blue: 0.51), .purple
    ]
    private let ticker = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    private var canSave: Bool { !name.isEmpty && !username.isEmpty && !password.isEmpty }
    private var canEnter: Bool { !username.isEmpty && !password.isEmpty }

    var body: some View {
        Group {
            if showLogin {
                loginView
            } else {
                webScreen
            }
        }
        .preferredColorScheme(.light)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            logout()
        }
    }

    // MARK: - Màn hình trang web

    private var webScreen: some View {
        ZStack {
            Color(red: 0.93, green: 0.93, blue: 0.93).ignoresSafeArea()
            WebView(url: siteURL, username: activeUser, password: activePass, reloadToken: reloadToken)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Màn hình đăng nhập

    private var loginView: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header
                    fields
                    buttonRow
                    savedList
                    footer
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
                .contentShape(Rectangle())
                .onTapGesture { hideKeyboard() }
            }

            if !toast.isEmpty {
                Text(toast)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .padding(.bottom, 24)
                    .transition(.opacity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("ĐĂNG NHẬP")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(brand)
            Rectangle()
                .fill(brand)
                .frame(width: 48, height: 3)
                .cornerRadius(2)
            Text("Đăng nhập nhanh vào VNHR")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.top, 36)
        .padding(.bottom, 8)
    }

    private var fields: some View {
        VStack(spacing: 16) {
            fieldRow("Tên", icon: "tag.fill") {
                TextField("Ví dụ: Tài khoản chính", text: $name)
                    .disableAutocorrection(true)
            }
            fieldRow("Tài khoản", icon: "person.fill") {
                TextField("ID tập đoàn hoặc mã nhân viên", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            fieldRow("Mật khẩu", icon: "lock.fill") {
                Group {
                    if showPassword {
                        TextField("Nhập mật khẩu", text: $password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        SecureField("Nhập mật khẩu", text: $password)
                    }
                }
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private func fieldRow<Content: View>(_ title: String, icon: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(brand)
                    .frame(width: 22)
                content()
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(fieldBg)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08), lineWidth: 1))
        }
    }

    private var buttonRow: some View {
        HStack(spacing: 14) {
            Button(action: saveAccount) {
                Text("Lưu")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(brand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(brand, lineWidth: 2))
            }
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.4)

            Button(action: enter) {
                Text("Vào")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(brand)
                    .cornerRadius(12)
            }
            .disabled(!canEnter)
            .opacity(canEnter ? 1 : 0.4)
        }
        .padding(.top, 4)
    }

    private var savedList: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bookmark.fill").foregroundColor(brand)
                Text("Danh Sách Lưu").font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(accounts.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(brand))
            }
            .foregroundColor(.black)
            .padding(14)
            Divider()

            if accounts.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "tray")
                        .font(.system(size: 26))
                        .foregroundColor(.gray)
                    Text("Chưa có tài khoản nào được lưu")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(22)
                .frame(maxWidth: .infinity)
            }

            ForEach(accounts) { acc in
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Button(action: { select(acc) }) {
                            HStack(spacing: 12) {
                                avatar(acc.name)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acc.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                    Text(acc.username)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if isSelected(acc) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(brand)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        Button(action: { delete(acc) }) {
                            Image(systemName: "trash")
                                .foregroundColor(Color.red.opacity(0.8))
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isSelected(acc) ? brand.opacity(0.07) : Color.clear)
                    Divider()
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private func avatar(_ text: String) -> some View {
        Text(String(text.prefix(1)).uppercased())
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(Circle().fill(brand))
    }

    private var footer: some View {
        Text("Developer : datpahm")
            .font(.system(size: 14, weight: .bold))
            .underline()
            .foregroundColor(rainbow[rainbowIndex])
            .animation(.easeInOut(duration: 0.25), value: rainbowIndex)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .onReceive(ticker) { _ in
                rainbowIndex = (rainbowIndex + 1) % rainbow.count
            }
    }

    // MARK: - Hành động

    private func isSelected(_ acc: SavedAccount) -> Bool {
        name == acc.name && username == acc.username
    }

    private func select(_ acc: SavedAccount) {
        name = acc.name
        username = acc.username
        password = acc.password
        hideKeyboard()
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
        hideKeyboard()
        haptic()
        showToast("Đã lưu \(n)")
    }

    private func delete(_ acc: SavedAccount) {
        accounts.removeAll { $0.id == acc.id }
        AccountStore.save(accounts)
    }

    private func enter() {
        guard canEnter else { return }
        haptic()
        activeUser = username
        activePass = password
        showLogin = false
        reloadToken += 1
    }

    private func logout() {
        activeUser = ""
        activePass = ""
        name = ""
        username = ""
        password = ""
        showPassword = false
        toast = ""
        showLogin = true
    }

    private func showToast(_ text: String) {
        withAnimation { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { toast = "" }
        }
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}