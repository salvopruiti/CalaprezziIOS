//
//  ScrapingClass.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 11/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import Foundation
import FirebaseMessaging
import SwiftSoup
import DeviceKit
import CoreTelephony
import Reachability

enum NotificationType: String {
    case Single = "single"
    case Package = "package"
    
}

class ScrapingClass {

    var markets = [Int: Market]()
    var limitedStockStrings = [String:Array<String>]()
    var unavailableStrings = [String:Array<String>]()
    var asin: String!
    var clientId: String!
    var notificationId: String!
    var hasError : Bool = false
    
    convenience init(_ notificationId: String, asin: String) {
        
        self.init();
        self.asin = asin
        self.notificationId = notificationId
        self.sendConfirmation(NotificationType.Single, notificationId: notificationId)
    }
    
    init() {
        clientId = Messaging.messaging().fcmToken
        
        markets[1] = Market(id: 1, name: "Italia", domain: "https://www.amazon.it", code: "it", sellerId: "A11IL2PNWYJU7H")
        markets[2] = Market(id: 2, name: "Germania", domain: "https://www.amazon.de", code: "de", sellerId: "A3JWKAKR8XB7XF")
        
        limitedStockStrings["it"] = [
            "Disponibilità: solo (1)",
            "Disponibilità: solo ([0-9]*)",
            "Solo ([0-9]*) con disponibilità immediata"
        ]
        
        limitedStockStrings["de"] = [
            "Nur noch ([0-9]*) Stück auf Lager - jetzt bestellen.",
            "Nur noch ([0-9]*) auf Lager"
        ]
        
        unavailableStrings["it"] = [
            "Attualmente non disponibile",
            "Non Disponibile"
        ]
        
        unavailableStrings["de"] = [
            "Nicht auf Lager",
            "Dieser Artikel ist noch nicht verfügbar",
            "Derzeit nicht auf Lager"
        ]

    }
    
    
    func register() {
        
        let url = URL(string: "https://app.calaprezzi.it/register")!
        let pref = UserDefaults.standard
        
        var request = URLRequest(url: url)
        
        let device = Device()
        let model = device.model
        
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"]!
        let buildNum = Bundle.main.infoDictionary!["CFBundleVersion"]!
        let app_version = "\(appVersion) (Build: \(buildNum))"
        let version = device.systemVersion
        let alias = pref.string(forKey: "alias")
        
        var postData = [String:Any]()
        
        postData["alias"] = alias
        postData["client_type"] = 2
        postData["unique_id"] = self.clientId
        postData["device_manufacturer"] = "Apple"
        postData["device_model"] = device.description
        postData["os_version"] = version
        postData["device_product"] = model
        postData["version"] = app_version
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: postData, options: [])
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let _ = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
        }
        task.resume()
    }
    
    func getAsin() {
        
        let asin = self.asin ?? "asin"
        
        let url = URL(string: "https://admin.calaprezzi.it/scraping-jobs/\(asin)")
        let _: String = downloadPage(url: url!)
    }
    
    func doScrape(_ asin: String, buyMarket: Market, sellMarket: Market) -> ScrapingResponse? {
        
        
        let start = DispatchTime.now()
        
      //prendo il prezzo più basso dal market di acquisto
        
        let userCountry = UserDefaults.standard.string(forKey: "user_country") ?? "IT"
        let url = URL(string: buyMarket.domain + "/gp/offer-listing/\(asin)/ref=dp_olp_0_ie=UTF8&condition=new")!
        
        var downloadedBytes: Int64 = 0
        var request = URLRequest(url: url)
        
        if(buyMarket.code.uppercased() == userCountry) {
            
            print("Devo Cambiare Indirizzo di Destinazione. Nazione di Acquisto: \(buyMarket.name)")
            
            if let cookies = changeAddress(buyMarket, code: sellMarket.code) {
                
                request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
                
            } else {
                print("Si è verificato un errore")
                hasError = true
                return nil
            }
            
        }
        
        request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")

        print("Scraping Lista Offerte Market di Acquisto (\(buyMarket.name))")

        let(data, response , error, _) = URLSession.shared.synchronousDataTask(urlrequest: request)
     
        guard error == nil || data == nil else {
            
            print("Si è verificato un errore!")
            print(error as! String)
            return nil
        }
        
        guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {
            
            print("Si è verificato un errore!")
            hasError = true
            
            return nil
        }
        
        downloadedBytes += httpStatus.expectedContentLength
        
        
     
        if let html = String(data: data!, encoding: .utf8) {
            let offers = parseOfferListingsPage(html, base: url.absoluteString)
            
            if(offers.count > 0) {
                
                let buyOffer = offers.first!
                if(buyOffer.sellerId == "") {
                    buyOffer.sellerId = buyMarket.sellerId
                }
                
                request.url = URL(string: buyMarket.domain + "/dp/\(asin)/?psc=1&m=" + buyOffer.sellerId)
                
                print("Scraping Pagina Prodotto, Market di Acquisto (\(buyMarket.name))")
                
                let(data, response , error, _) = URLSession.shared.synchronousDataTask(urlrequest: request)
                
                guard error == nil || data == nil else {
                    
                    print("Si è verificato un errore!")
                    return nil
                }
                
                guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {
                    
                    hasError = true
                    return nil
                }
                
               
                downloadedBytes += httpStatus.expectedContentLength
            
                
                if let html = String(data: data!, encoding: .utf8) {
                
                    let productData = parseProductPage(html, base: (request.url?.absoluteString)!)
                    
                    
                    
                    //dati prezzo di vendita
                    
                    request = URLRequest(url: URL(string: sellMarket.domain + "/gp/offer-listing/\(asin)/ref=dp_lp_0?ie=UTf8&condition=new")!)
                    
                    request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
                    
                    print("Scraping Lista Offerte Market di Vendita (\(sellMarket.name))")
                    
                    let(data, response, error, _) = URLSession.shared.synchronousDataTask(urlrequest: request)
                    
                    guard error == nil || data == nil else {
                        
                        print("Si è verificato un errore!")
                        return nil
                    }
                    
                    guard let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode == 200 else {
                        
                        hasError = true
                        return nil
                    }
                    
                    
                    
                    
                    downloadedBytes += httpStatus.expectedContentLength
                    
                    if let html = String(data: data!, encoding: .utf8) {
                        
                        let sellOffers = parseOfferListingsPage(html, base: (request.url?.absoluteString)!)
                        
                        let end = DispatchTime.now()
                        
                        let time = Int((end.uptimeNanoseconds - start.uptimeNanoseconds) / 1000000000) //nanosecondi a secondi
                        

                        let scrapingResponse = ScrapingResponse(asin, buy: buyMarket, sell: sellMarket, data: productData, buyOffers: offers, sellOffers: sellOffers, time: time, length: UInt(downloadedBytes) )
                        
                    
                        
                        print("Scraping Completato Senza Errori in \(time) secondi")
                        print(scrapingResponse)
                        
                        return scrapingResponse
                        
                        
                        
                        
                    }
                }
                
            }
            
            
            
        }
        

        
        return nil
        
    }
    
    func sendErrorResponse() {
        
        //TODO
        
        
    }
    
    func downloadPage(url: URL) -> String {
   
        var request = URLRequest(url: url)
        request.httpMethod = "GET";
        request.addValue(clientId, forHTTPHeaderField:  "CP-UNIQUE-ID")
        
        let(data, response , _ ,_) = URLSession.shared.synchronousDataTask(urlrequest: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("DownloadPage - Risposta non valida")
            return ""
        }
        
        guard let responseData = data else {
            print("DownloadPage - Dati non ricevuti")
            return ""
        }
        
        var downloadedBytes: Int64 = 0
        
        downloadedBytes += httpResponse.expectedContentLength
        
        print("ScrapingJobs Scaricati - Downloaded Bytes: " + String(downloadedBytes))
        
        let decoder = JSONDecoder()
        let jobs = try! decoder.decode([Job].self, from: responseData)
        
        
        jobs.forEach { job in
            
            print("Categoria: \(job.categoryName)")
            
            var results: [ScrapingResponse] = [ScrapingResponse]()
            
            job.products.forEach( { product in
                
                print("Prodotto da analizzare: \(product.asin)")
                
                let buyMarket = self.markets[product.buyMarketId]
                let sellMarket = self.markets[product.sellMarketId]
                
                if let response = self.doScrape(product.asin, buyMarket: buyMarket!, sellMarket: sellMarket!) {
                   
                    downloadedBytes += Int64(response.downloadedBytes)
                    results.append(response)
                } else {
                    print("Si è verificato un errore durante lo Scraping!")
                }
                
            })
            
            //invio conferma al server
            
            var request: URLRequest
            
            if(results.count == 0 && !hasError) {
                request = URLRequest(url: URL(string: "https://app.calaprezzi.it/scraping/completed")!)
            } else {
                request = URLRequest(url: URL(string: "https://admin.calaprezzi.it/prodotti/" + job.searchIndex + "/push")!)
            }
            
            request.addValue(clientId, forHTTPHeaderField: "CP-UNIQUE-ID")
            
            request.httpMethod = "POST"
            
            let (networkTypeId, networkTypeName) = self.getNetworkType()
            
            let postData = Response(notificationId: notificationId ?? "", productsCount: job.products.count, productsChecked: results.count, bytesDownloaded: downloadedBytes, has503Error: hasError, results: results, networkTypeID: networkTypeId, networkTypeName: networkTypeName)
            
            
             let encoder = JSONEncoder()
            
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try! encoder.encode(postData)
            
           
            request.httpBody = jsonData
            
            _ = URLSession.shared.synchronousDataTask(urlrequest: request)
            
        }

        
        return ""

    }
    
    
    func sendConfirmation(_ notificationType: NotificationType, notificationId: String)
    {
        let url = URL(string: "https://app.calaprezzi.it/scraping/confirm")
        var body = [String: Any]()
        
        body["notification_id"] = notificationId
        body["notification_type"] = notificationType.rawValue
        body["client_id"] = clientId
        
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: body,
            options: []) {
            let JSONText = String(data: theJSONData,
                              encoding: .ascii)!
    
            //client_id e asin se disponibile
            
            var request = URLRequest(url: url!)
            
            request.httpMethod = "POST"
            request.httpBody = JSONText.data(using: .utf8);
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let _ = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(String(describing: error))")
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(String(describing: response))")
                }
                
                //let responseString = String(data: data, encoding: .utf8)
                //print("responseString = \(String(describing: responseString))")
            }
            task.resume();
        }
        
    }
    
    func changeAddress(_ market: Market, code countryCode : String) -> [HTTPCookie]? {
        
        let url = URL(string: market.domain + "/gp/delivery/ajax/address-change.html")
        
        if let url = url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
            request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.addValue(market.domain, forHTTPHeaderField: "Origin")
            request.addValue(market.domain + "/ref=nav_logo", forHTTPHeaderField: "Referer")
            request.addValue("text/html, */*", forHTTPHeaderField: "Accept")
            request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
            
            request.httpBody = ("locationType=COUNTRY&district=\(countryCode)&countryCode=\(countryCode)&deviceType=web&pageType=Gateway&actionSource=glow").data(using: .utf8)
            
            
            let(data, _, _, cookies) = URLSession.shared.synchronousDataTask(urlrequest: request)
            
            guard let responseData = data else {
                print("ChangeAddress - Errore: Nessun Dato Ricevuto")
                return nil
            }
            
            guard let resp = try! JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
                
                print("ChangeAddress - Errore durante il Parsing dei Risultati")
                return nil
            }
            
            if(resp["isValidAddress"] as? Bool == true) {
                
                print("ChangeAddress: Valid Address!")
                
                if(cookies.count > 0) {
                    return cookies
                }
                
            } else {
                print("Change Address: " + (resp["isValidAddress"] as! String))
                
                return nil
            }
            
        }
        
        
        return nil
        
        
    }
    
    func extractNumberFromString(_ string: String ) -> Float? {
        
        let regex = try! NSRegularExpression(pattern: "[^0-9/.,]")
        let range = NSMakeRange(0, string.count)
        
        var result = regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        
        let comma = result.index(of: ",")?.encodedOffset ?? nil
        let point = result.index(of: ".")?.encodedOffset ?? nil
        
        if (comma != nil && point != nil) {
            
            let symbol = comma! > point! ? "." : ","
            
            result = result.replacingOccurrences(of: symbol, with: "")
            
        }
        
        result = result.replacingOccurrences(of: ",", with: ".")
        
        return Float(result)
    
    }

    func parseOfferListingsPage(_ html : String, base baseUri: String) -> [Offer] {
        
        var offers = [Offer]()
        let document : Document? = try! SwiftSoup.parseBodyFragment(html, baseUri)
        
        if let document = document {
            
            do {
                try document.select("#olpOfferList div.olpOffer").forEach({element in
                
                    let offer: Offer = Offer()
                
                    
                    if let price = try! element.select(".olpOfferPrice").first()?.text() {
                        offer.price = extractNumberFromString(price) ?? 0
                    }
                    
                    if let price = try! element.select(".olpShippingInfo .olpShippingPrice").first()?.text() {
                        offer.shipping = extractNumberFromString(price) ?? 0
                    }
                    
                    if let price = try! element.select(".olpPromotion").first()?.text() {
                        offer.promo = extractNumberFromString(price)!
                    }
                    
                    offer.condition = try! element.select(".olpCondition").first()?.text() ?? ""
                    
                    if let promo = offer.promo {
                        offer.price -= ((offer.price / 100) * promo)
                    }
                    
                    offer.total = offer.price + offer.shipping
                    
                    let seller = try! (element.select(".olpSellerName a").first())
                    
                    if let seller = seller {
                        offer.sellerName = try! seller.text()
                        offer.sellerUrl = try! seller.absUrl("href")
                    
                        if let query = URLComponents(string: offer.sellerUrl) {
                            //query?.queryItems?.first(where: {$0.name == "isAmazonFulFilled"})
                            offer.sellerId = query.queryItems?.first(where: {$0.name == "seller" })?.value ?? ""
                        }
                    } else {
                        //amazon
                        
                        offer.isAmazonFulFilled = true
                        offer.sellerName = try! (element.select(".olpSellerName img").first()?.attr("alt")) ?? "Amazon"
                    }
            
                    offers.append(offer)
                })
                
            } catch {
                print(error)
            }
            
            
        }
        
        

        return offers
        
    }
    func parseProductPage(_ html: String, base baseUri : String) -> ProductData  {
        
        let document : Document? = try! SwiftSoup.parse(html, baseUri)
        
        let data = ProductData()
        
        
        if let document = document {
            
            let destination = try! document.select("#glow-ingress-block").first()?.text()
            
            if let destination = destination {
                print("Destinazione: " + destination)
            }

           
            data.ourPrice = try! document.select("#priceblock_ourprice").first()?.text()
            data.dealPrice = try! document.select("#priceblock_dealprice").first()?.text()
            data.salePrice = try! document.select("#priceblock_saleprice").first()?.text()
            data.price3P = try! document.select(".price3P").first()?.text()
            data.ourPriceShippingMessage = try! document.select("#ourprice_shippingmessage").first()?.text()
            data.dealPriceShippingMessage = try! document.select("#dealprice_shippingmessage").first()?.text()
            data.salePriceShippingMessage = try! document.select("#saleprice_shippingmessage").first()?.text()
            
            if let element = try! document.select(".shipping3P").first() {
                data.shipping3P = try! element.text()
            } else {
                data.shipping3P = try! document.select("#ourPrice_availability").first()?.text()
            }
            data.merchantInfo = try! document.select("#merchant-info").first()?.text();
            data.merchantInfoUrl = try! document.select("#merchant-info a").first()?.absUrl("href")
            data.olp = try! document.select("[data-feature-name=olp]").first()?.html()
            
            if let message = try! document.select("[data-feature-name=availability] #availability").first()?.text() {
                
                data.availability = message
                
                var qty: Int?
                
                unavailableLoop: for (_, strings) in unavailableStrings {
                    
                    for regexPattern in strings {
                        
                        let regex = try! NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
                        let range = NSMakeRange(0, message.count)
                        
                        if(regex.numberOfMatches(in: message, options: [], range: range) > 0) {
                            qty = 0
                            break unavailableLoop
                        }
                        
                        
                    }
                    
                }
                
                if qty == nil {
                    
                    
                    qty = 21
                    
                    codesLoop: for (_, strings) in limitedStockStrings {
                        
                        for regexPattern in strings {
                            
                            let regex = try! NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
                            let range = NSMakeRange(0, message.count)
                            
                            if let match = regex.firstMatch(in: message, options: [], range: range) {
                                
                                if let range = Range(match.range(at: 1), in: message) {
                                    
                                    qty = Int(String(message[range]))!
                                    break codesLoop
                                }
                                
                            }
                        }
                    }
                }
                
                data.qty = qty!
                
                print("Message: \(message), Qty: \(String(describing: qty))")
                
            }
            
            data.holidayDeliveryMessage = try! document.select("[data-feature-name=holidayDeliveryMessage]").first()?.text()
            data.dynamicDeliveryMessage = try! document.select("[data-feature-name=dynamicDeliveryMessage] #ddmDeliveryMessage").first()?.text()
            data.shippingWeight = try! document.select(".shipping-weight .value").first()?.text()
            data.apEligibility = try! document.select("[data-feature-name=apEligibility]").first()?.text()

            
            
            
        }
        
        return data
    
    }
    
    func getNetworkType()-> (networkTypeId: Int, networkTypeName: String) {
        do {
            
            if let reachability = Reachability() {
                
                let status = reachability.connection
        
                if(status == .none) {
                    return (-1, "Sconosciuto")
                }
                
                if(status == .wifi) {
                    return (1, "Wifi")
                }
                
                if(status == .cellular) {
                    
                    let networkInfo = CTTelephonyNetworkInfo()
                    let carrierType = networkInfo.currentRadioAccessTechnology
                    switch carrierType {
                        case CTRadioAccessTechnologyGPRS?,CTRadioAccessTechnologyEdge?,CTRadioAccessTechnologyCDMA1x?:
                            return (0, "Mobile (2G)")
                        case CTRadioAccessTechnologyWCDMA?,CTRadioAccessTechnologyHSDPA?,CTRadioAccessTechnologyHSUPA?,CTRadioAccessTechnologyCDMAEVDORev0?,CTRadioAccessTechnologyCDMAEVDORevA?,CTRadioAccessTechnologyCDMAEVDORevB?,CTRadioAccessTechnologyeHRPD?:
                            return (0, "Mobile (3G)")
                        case CTRadioAccessTechnologyLTE?:
                            return (0, "Mobile (4G)")
                        
                    default:
                        return(-1, "Sconosciuto")
                    }

                }
                
                
                
            }
            
        }
        
        return (-1, "Sconosciuto")
    }
}


