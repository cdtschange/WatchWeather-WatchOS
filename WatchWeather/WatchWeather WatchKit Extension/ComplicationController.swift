//
//  ComplicationController.swift
//  WatchWeather WatchKit Extension
//
//  Created by Mao on 08/10/2016.
//  Copyright © 2016 pinteccdts. All rights reserved.
//

import ClockKit
import WatchWeatherWatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Forward, .Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        var date: NSDate? = nil
        let (requestDate, weathers) = Weather.storedWeathers()
        
        if let weathers = weathers,
            requestDate = requestDate {
            for w in weathers where w != nil {
                if w!.day == .DayBeforeYesterday {
                    date = w!.dateByDayWithRequestDate(requestDate)
                    break
                }
            }
        }
        
        handler(date)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        var date: NSDate? = nil
        let (requestDate, weathers) = Weather.storedWeathers()
        
        if let weathers = weathers,
            requestDate = requestDate {
            for w in weathers where w != nil {
                if w!.day == .DayAfterTomorrow {
                    //最早的时间是前天的 00:00，这是毫无疑问的。但是最晚的可显示时间并不是后天的 00:00，而是 23:59:59
                    date = w!.dateByDayWithRequestDate(requestDate) + 1.day - 1.second
                    break
                }
            }
        }
        
        handler(date)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        var entry : CLKComplicationTimelineEntry?
        
        // Create the template and timeline entry.
        let (requestDate, weathers) = Weather.storedWeathers()
        
        if let weathers = weathers,
            requestDate = requestDate {
            for w in weathers where w != nil {
                
                let weatherDate = w!.dateByDayWithRequestDate(requestDate)
                if weatherDate == NSDate.today() {
                    
                    if let template = templateForComplication(complication, weatherState: w!.state) {
                        entry = CLKComplicationTimelineEntry(date: weatherDate, complicationTemplate: template)
                    }
                }
            }
        }
        
        // Pass the timeline entry back to ClockKit.
        handler(entry)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        var entries = [CLKComplicationTimelineEntry]()
        let (requestDate, weathers) = Weather.storedWeathers()
        
        if let weathers = weathers,
            requestDate = requestDate {
            for w in weathers where w != nil {
                let weatherDate = w!.dateByDayWithRequestDate(requestDate)
                if weatherDate < date {
                    if let template = templateForComplication(complication, weatherState: w!.state) {
                        let entry = CLKComplicationTimelineEntry(date: weatherDate, complicationTemplate: template)
                        entries.append(entry)
                        
                        if entries.count == limit {
                            break
                        }
                    }
                }
            }
        }
        
        handler(entries)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        var entries = [CLKComplicationTimelineEntry]()
        let (requestDate, weathers) = Weather.storedWeathers()
        
        if let weathers = weathers,
            requestDate = requestDate {
            for w in weathers where w != nil {
                let weatherDate = w!.dateByDayWithRequestDate(requestDate)
                if weatherDate > date {
                    if let template = templateForComplication(complication, weatherState: w!.state) {
                        let entry = CLKComplicationTimelineEntry(date: weatherDate, complicationTemplate: template)
                        entries.append(entry)
                        
                        if entries.count == limit {
                            break
                        }
                    }
                }
            }
        }
        
        handler(entries)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(NSDate.tomorrow());
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(templateForComplication(complication, weatherState: .Sunny))
    }
    
    static func reloadComplications() {
        let server = CLKComplicationServer.sharedInstance()
        if let complications = server.activeComplications {
            for complication in complications {
                server.reloadTimelineForComplication(complication)
            }
        }
    }
    
    private func templateForComplication(complication: CLKComplication, weatherState: Weather.State) -> CLKComplicationTemplate? {
        let imageTemplate: CLKComplicationTemplate?
        
        if complication.family == .ModularSmall {
            imageTemplate = CLKComplicationTemplateModularSmallSimpleImage()
            
            let imageName: String
            switch weatherState {
            case .Sunny: imageName = "sunny"
            case .Cloudy: imageName = "cloudy"
            case .Rain: imageName = "rain"
            case .Snow: imageName = "snow"
            }
            
            (imageTemplate as! CLKComplicationTemplateModularSmallSimpleImage).imageProvider = CLKImageProvider(onePieceImage:UIImage(named: imageName)!)
        } else {
            imageTemplate = nil
        }
        
        return imageTemplate
    }
}
