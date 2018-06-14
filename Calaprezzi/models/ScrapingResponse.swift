//
//  ScrapingResponse.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 12/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import Foundation

class ScrapingResponse : Codable {
    var asin: String = ""
    var buyMarketId : Int?
    var sellMarketId: Int?
    var productData: ProductData?
    var buyOffers: [Offer]?
    var sellOffers: [Offer]?
    var elapsedTime : Int = 0
    var downloadedBytes : UInt = 0
    
    enum CodingKeys : String, CodingKey {
        case asin
        case buyMarketId = "buy_market_id"
        case sellMarketId = "sell_market_id"
        case productData = "data"
        case buyOffers = "buyPrices"
        case sellOffers = "sellPrices"
        case elapsedTime = "elapsed_time"
        case downloadedBytes = "downloaded_bytes"
    }
    
    init() {
        
    }
    
    init(_ asin: String, buy buyMarket: Market, sell sellMarket: Market, data productData: ProductData, buyOffers: [Offer], sellOffers: [Offer], time elapsedTime : Int, length downloadedBytes :UInt)  {
        
        self.asin = asin
        self.buyMarketId = buyMarket.id
        self.sellMarketId = sellMarket.id
        self.productData = productData
        self.buyOffers = buyOffers
        self.sellOffers = sellOffers
        self.elapsedTime = elapsedTime
        self.downloadedBytes = downloadedBytes
    }
}
