//
//  Extensions.swift
//  Calaprezzi
//
//  Created by Salvatore Pruiti on 13/06/18.
//  Copyright © 2018 Salvatore Pruiti. All rights reserved.
//

import Foundation


extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (data: Data?, response: URLResponse?, error: Error?, cookies: [HTTPCookie]) {
        
        var data: Data?
        var response: URLResponse?
        var error: Error?
        var cookies = [HTTPCookie]()
        
        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        let httpUrlResponse = response as! HTTPURLResponse
        if let url = response?.url,
            let headerFields = httpUrlResponse.allHeaderFields as? [String:String] {
            
            cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            
        }
        
        return (data, response, error, cookies)
        
    }
}
