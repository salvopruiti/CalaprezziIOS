//
//  Job.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 12/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import Foundation

struct JobProduct: Codable {
    let asin: String;
    let buyMarketId: Int
    let sellMarketId: Int
    enum CodingKeys : String, CodingKey {
        case asin
        case buyMarketId = "buy_market_id"
        case sellMarketId = "sell_market_id"
    }
}

struct Job : Codable {
    let categoryName: String
    let products: Array<JobProduct>
    let searchIndex: String
    enum CodingKeys : String, CodingKey {
        case categoryName = "category_name"
        case products
        case searchIndex = "search_index"
    }
    
}
