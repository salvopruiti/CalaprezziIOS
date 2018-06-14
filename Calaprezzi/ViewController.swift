//
//  ViewController.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 09/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import UIKit
import WebKit
import FirebaseInstanceID
import FirebaseMessaging
import SwiftSoup

class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView : WKWebView!

    @IBOutlet weak var btnScrape: UIButton!
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }

    @IBAction func buttonClick(_ sender: Any) {
        
        var sclass = ScrapingClass()
        
        sclass.asin = "B07C21Q43C"
        
        sclass.getAsin()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://app.calaprezzi.it")
        let request = URLRequest(url: url! as URL)

        webView = WKWebView(frame: self.view.frame)
        webView.navigationDelegate = self
        webView.load(request as URLRequest)
        self.view.addSubview(webView)
        self.view.sendSubview(toBack: webView)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

