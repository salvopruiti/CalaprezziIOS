//
//  ProductData.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 12/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import Foundation

class ProductData : Codable {
    
    var apEligibility: String?
    var shippingWeight: String?
    var dynamicDeliveryMessage: String?
    var holidayDeliveryMessage: String?
    var availability: String?
    var olp: String?
    var merchantInfoUrl: String?
    var merchantInfo: String?
    var shipping3P: String?
    var salePriceShippingMessage: String?
    var dealPriceShippingMessage: String?
    var ourPriceShippingMessage: String?
    var price3P: String?
    var salePrice: String?
    var dealPrice: String?
    var ourPrice: String?
    var qty : Int = 21
    
    enum CodingKeys : String, CodingKey {
        case apEligibility
        case shippingWeight
        case dynamicDeliveryMessage
        case holidayDeliveryMessage
        case availability
        case olp
        case merchantInfoUrl
        case merchantInfo
        case shipping3P
        case salePriceShippingMessage = "saleprice_shippingmessage"
        case dealPriceShippingMessage = "dealprice_shippingmessage"
        case ourPriceShippingMessage = "ourprice_shippingmessage"
        case price3P
        case salePrice = "saleprice"
        case dealPrice = "dealprice"
        case ourPrice = "ourprice"
        case qty
    }
    
    init() {
        
    }
    
}
