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
    
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var btnScrape: UIButton!
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }

    
    @IBAction func optionsclick(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
         let welcomeController = storyBoard.instantiateViewController(withIdentifier: "NuovoController")
         
         self.present(welcomeController, animated: true, completion: nil)
    }
    @IBAction func buttonClick(_ sender: Any) {
        
       
        
        ScrapingClass().getAsin()
        
    }
        
    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)
        
        let prefs = UserDefaults.standard,
            installed = prefs.bool(forKey: "configurated")
        
        guard installed else {
            
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let welcomeController = storyBoard.instantiateViewController(withIdentifier: "NuovoController")
            
            self.present(welcomeController, animated: true, completion: nil)
            
            return
            
        }
        
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

