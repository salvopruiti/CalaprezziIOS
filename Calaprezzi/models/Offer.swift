//
//  ScrapingResponse.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 12/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import Foundation

class Offer : Codable {
    var price: Float = 0
    var shipping : Float = 0
    var promo : Float?
    var total : Float?
    var condition: String = ""
    var sellerName : String = ""
    var sellerUrl: String = ""
    var sellerId: String = ""
    var isAmazonFulFilled : Bool = false

    init() {
        
    }
}
