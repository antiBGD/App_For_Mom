import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    let username: String
    let password: String
    let reloadToken: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        context.coordinator.web = web
        context.coordinator.begin()
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.lastToken != reloadToken {
            context.coordinator.lastToken = reloadToken
            context.coordinator.begin()
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var lastToken: Int
        weak var web: WKWebView?
        var autoTried = false
        var pollId = 0
        var loadRetries = 0

        init(_ parent: WebView) {
            self.parent = parent
            self.lastToken = parent.reloadToken
        }

        func begin() {
            autoTried = false
            loadRetries = 0
            web?.load(URLRequest(url: parent.url))
            startPolling()
        }

        private func startPolling() {
            guard !parent.username.isEmpty, !parent.password.isEmpty else { return }
            pollId += 1
            attempt(id: pollId, count: 0)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            if !autoTried { startPolling() }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if !autoTried { startPolling() }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            retryLoad(error)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            retryLoad(error)
        }

        private func retryLoad(_ error: Error) {
            if (error as NSError).code == NSURLErrorCancelled { return }
            guard !autoTried, loadRetries < 3 else { return }
            loadRetries += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self, !self.autoTried, let web = self.web else { return }
                web.load(URLRequest(url: self.parent.url))
            }
        }

        private func attempt(id: Int, count: Int) {
            guard id == pollId, !autoTried, count < 120, let web = web else { return }
            web.evaluateJavaScript(script()) { [weak self] result, _ in
                guard let self = self, id == self.pollId else { return }
                if let status = result as? String, status == "clicked" {
                    self.autoTried = true
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.attempt(id: id, count: count + 1)
                    }
                }
            }
        }

        private func literal(_ s: String) -> String {
            guard let data = try? JSONSerialization.data(withJSONObject: [s]),
                  let str = String(data: data, encoding: .utf8) else { return "\"\"" }
            return String(str.dropFirst().dropLast())
        }

        private func script() -> String {
            return """
            (function(u, p) {
              var pass = document.querySelector('input[type="password"]');
              if (!pass) return 'nofield';
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
              var same = (!user || user.value === u) && pass.value === p;
              window.__qlFills = window.__qlFills || 0;
              if (!same && window.__qlFills < 6) {
                if (user) setVal(user, u);
                setVal(pass, p);
                window.__qlFills += 1;
                window.__qlStable = 0;
                return 'filled';
              }
              window.__qlStable = (window.__qlStable || 0) + 1;
              if (window.__qlStable < 2) return 'waiting';
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
              if (!btn) return 'nobutton';
              btn.click();
              return 'clicked';
            })(\(literal(parent.username)), \(literal(parent.password)));
            """
        }
    }
}