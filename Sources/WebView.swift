import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    let username: String
    let password: String
    let reloadToken: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.navigationDelegate = context.coordinator
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.lastToken != reloadToken {
            context.coordinator.lastToken = reloadToken
            context.coordinator.autoTried = false
            web.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastToken: Int
        var autoTried = false

        init(_ parent: WebView) {
            self.parent = parent
            self.lastToken = parent.reloadToken
        }

        private func literal(_ s: String) -> String {
            guard let data = try? JSONSerialization.data(withJSONObject: [s]),
                  let str = String(data: data, encoding: .utf8) else { return "\"\"" }
            return String(str.dropFirst().dropLast())
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !autoTried, !parent.username.isEmpty, !parent.password.isEmpty else { return }
            let js = """
            (function(u, p) {
              var pass = document.querySelector('input[type="password"]');
              if (!pass) return false;
              var inputs = Array.from(document.querySelectorAll('input')).filter(function(i) {
                return ['text','email','tel','number'].indexOf(i.type) >= 0 && i.offsetParent !== null;
              });
              var before = inputs.filter(function(i) {
                return i.compareDocumentPosition(pass) & Node.DOCUMENT_POSITION_FOLLOWING;
              });
              var user = before.length ? before[before.length - 1] : inputs[0];
              function setVal(el, v) {
                var setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
                setter.call(el, v);
                el.dispatchEvent(new Event('input', {bubbles: true}));
                el.dispatchEvent(new Event('change', {bubbles: true}));
              }
              if (user) setVal(user, u);
              setVal(pass, p);
              var scope = pass.form || document;
              var btn = scope.querySelector('button[type=submit],input[type=submit]');
              if (!btn) {
                var words = ['登录', '登錄', '登入', 'Login', 'Log in', 'Đăng nhập'];
                var all = Array.from(document.querySelectorAll('button,input[type=button],a,div,span'));
                btn = all.filter(function(e) {
                  var t = (e.innerText || e.value || '').trim();
                  return words.indexOf(t) >= 0;
                }).pop();
              }
              setTimeout(function() { if (btn) btn.click(); }, 400);
              return true;
            })(\(literal(parent.username)), \(literal(parent.password)));
            """
            webView.evaluateJavaScript(js) { [weak self] result, _ in
                if let ok = result as? Bool, ok { self?.autoTried = true }
            }
        }
    }
}