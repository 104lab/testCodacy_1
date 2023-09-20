//
//  ViewController.swift
//  Nabi
//
//  Created by aaron.du on 2018/9/26.
//  Copyright © 2018年 aaron.du. All rights reserved.
//

import UIKit
import WebKit
class ViewController: UIViewController {
    var webView: WKWebView!
    var redirectURL : String?
    let ScreenWidth: CGFloat = UIScreen.main.bounds.width
    let ScreenHeight: CGFloat = UIScreen.main.bounds.height
    let StatusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
    let awsToken = "ASDDS/wxswilsone2DEIDFkajlsejioSDJSDIOFJLEWJFL"
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        }
        return .default
    }
    
    func setURLReload(urlString: String){
        redirectURL = urlString
        if let redirectURLString = redirectURL , let redirectUrl = URL(string: redirectURLString) {
            webView.load(URLRequest(url: redirectUrl))
            redirectURL = ""
        }
    }

    override func viewDidLoad() {

        super.viewDidLoad()
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webViewHeight = ScreenHeight - StatusBarHeight
        webView = WKWebView(frame: CGRect(x: 0, y: StatusBarHeight, width: ScreenWidth, height: webViewHeight), configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        view.addSubview(webView)
        
        // 重新拿webView去setHTTPCookieStorage的值，才可以立即生效
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        for cookie in cookies {
            if #available(iOS 11.0, *) {
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        
        // 載入網頁
        let url = URL(string: Domain.CONNECT_DOMAIN)!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 13.0, *) {
            let app = UIApplication.shared
            let statusBarHeight: CGFloat = app.statusBarFrame.size.height
            
            let statusbarView = UIView()
            statusbarView.backgroundColor = UIColor.white
            statusbarView.tintColor = UIColor.black
            view.addSubview(statusbarView)
          
            statusbarView.translatesAutoresizingMaskIntoConstraints = false
            statusbarView.heightAnchor
                .constraint(equalToConstant: statusBarHeight).isActive = true
            statusbarView.widthAnchor
                .constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
            statusbarView.topAnchor
                .constraint(equalTo: view.topAnchor).isActive = true
            statusbarView.centerXAnchor
                .constraint(equalTo: view.centerXAnchor).isActive = true
          
        } else {
            let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
            statusBar?.backgroundColor = UIColor.white
        }
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
            let url = navigationResponse.response.url
            else {
                decisionHandler(.cancel)
                return
        }
        
        if let headerFields = response.allHeaderFields as? [String: String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            cookies.forEach { (cookie) in
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url , let urlString = navigationAction.request.url?.absoluteString {
            var checkUrl = urlString
            print(checkUrl)
            if checkUrl.contains("action=browser") {
                //如果url中有 action=browser , 就外開
                UIApplication.shared.openURL(url)
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate
extension ViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
