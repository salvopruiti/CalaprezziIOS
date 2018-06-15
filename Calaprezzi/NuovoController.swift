//
//  NuovoController.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 15/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import UIKit
import Foundation

class NuovoController : UIViewController, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
    
        view.addGestureRecognizer(tapGesture)
        
        nameField.text = UserDefaults.standard.string(forKey: "alias")
        nameField.delegate = self
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBAction func saveName(_ sender: Any) {
        
        let pref = UserDefaults.standard
        
        guard let alias = nameField.text, alias.count > 2 else {
            
            let alert = UIAlertController(title: "Attenzione", message: "Non hai inserito un nome valido!", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
                    
                case .cancel:
                    print("cancel")
                    
                case .destructive:
                    print("destructive")
                    
                    
                }}))
            
            self.present(alert, animated: true, completion: nil)

            return
        }
        
        pref.set(alias, forKey: "alias")
        pref.set(pref.string(forKey: "user_country") ?? "IT", forKey: "user_country")
        pref.set(true, forKey: "configurated")
        
        ScrapingClass().register()
        
        print("Impostazioni Salvate!")
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let welcomeController = storyBoard.instantiateViewController(withIdentifier: "MainController")
        
        self.present(welcomeController, animated: true, completion: nil)    }

    
}
