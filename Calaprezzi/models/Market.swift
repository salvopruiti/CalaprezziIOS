//
//  Market.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 12/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import Foundation

class Market : Codable {
    
    var id: Int
    var name: String
    var domain: String
    var code: String
    var sellerId: String
    enum CodingKeys : String, CodingKey {
        case id
        case name
        case domain
        case code
        case sellerId = "seller_id"
    }
    
    init(id: Int, name: String, domain: String, code: String, sellerId: String) {
        self.id = id
        self.name = name;
        self.domain = domain;
        self.code = code;
        self.sellerId = sellerId;
    }
    
}
