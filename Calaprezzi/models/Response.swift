//
//  Market.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 12/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import Foundation

struct Response : Codable {
    
    var notificationId : String = ""
    var productsCount : Int = 0
    var productsChecked : Int = 0
    var bytesDownloaded : Int64 = 0
    var has503Error : Bool = false
    var results : [ScrapingResponse] = [ScrapingResponse]()
    
    enum CodingKeys : String, CodingKey {
        case notificationId = "notification_id"
        case productsCount = "products_count"
        case productsChecked = "products_checked"
        case bytesDownloaded = "bytes_downloaded"
        case has503Error = "has_503_error"
        case results
    }
}
