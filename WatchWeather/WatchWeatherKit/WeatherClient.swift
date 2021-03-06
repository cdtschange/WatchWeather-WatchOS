//
//  WeatherClient.swift
//  WatchWeather
//
//  Created by Mao on 08/10/2016.
//  Copyright © 2016 pinteccdts. All rights reserved.
//

import Foundation

public let WatchWeatherKitErrorDomain = "com.cdts.WatchWeatherKit.error"
public struct WatchWeatherKitError {
    public static let CorruptedJSON = 1000
}

public struct WeatherClient {
    
    public static let sharedClient = WeatherClient()
    let session = NSURLSession(configuration: NSURLSessionConfiguration.ephemeralSessionConfiguration())
    
    public func requestWeathers(handler: ((weathers: [Weather?]?, error: NSError?) -> Void)?) {
        
        guard let url = NSURL(string: "https://raw.githubusercontent.com/cdtschange/WatchWeather-WatchOS/master/WatchWeather/Data/data.json") else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                handler?(weathers: nil, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: nil))
            })
            return
        }
        
        let task = session.dataTaskWithURL(url) { (data, response, error) -> Void in
            if error != nil {
                handler?(weathers: nil, error: error)
            } else {
                do {
                    let object = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    if let dictionary = object as? [String: AnyObject] {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let weathers = Weather.parseWeatherResult(dictionary)
                            if weathers != nil {
                                Weather.storeWeathersResult(dictionary, requestDate: NSDate())
                            }
                            handler?(weathers: weathers, error: nil)
                        })
                    }
                } catch _ {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        handler?(weathers: nil, error: NSError(domain: WatchWeatherKitErrorDomain, code: WatchWeatherKitError.CorruptedJSON, userInfo: nil))
                    })
                }
            }
        }
        
        task.resume()
    }
}