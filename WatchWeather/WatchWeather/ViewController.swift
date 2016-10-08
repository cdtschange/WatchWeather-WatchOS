//
//  ViewController.swift
//  WatchWeather
//
//  Created by Mao on 08/10/2016.
//  Copyright © 2016 pinteccdts. All rights reserved.
//

import UIKit
import WatchWeatherKit
import WatchConnectivity

class ViewController: UIPageViewController {
    
    var data: [Day: Weather] = [:]
    var session: WCSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session!.delegate = self
            session!.activateSession()
        }
        
        dataSource = self
        
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.whiteColor()
        setViewControllers([vc], direction: .Forward, animated: true, completion: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.becomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func becomeActive() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if self.shouldRequest() {
                self.request()
            } else {
                let (_, weathers) = Weather.storedWeathers()
                if let weathers = weathers {
                    self.updateWeathers(weathers)
                }
            }
        }
    }
    
    func shouldRequest() -> Bool {
        let (requestDate, _) = Weather.storedWeathers()
        return requestDate < NSDate.today()
    }
    
    func request() {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        WeatherClient.sharedClient.requestWeathers { [unowned self] (weathers, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error == nil && weathers != nil {
                self.updateWeathers(weathers!)
                
                if let dic = Weather.storedWeathersDictionary() {
                    do {
                        try self.session?.updateApplicationContext(dic)
                    } catch _ {
                        
                    }
                }
            } else {
                let alert = UIAlertController(title: "Error", message: error?.description ?? "Unknown Error", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func updateWeathers(weathers: [Weather?]) {
        for w in weathers where w != nil {
            self.data[w!.day] = w
        }
        
        let vc = self.weatherViewControllerForDay(.Today)
        self.setViewControllers([vc], direction: .Forward, animated: false, completion: nil)
    }
    
    func weatherViewControllerForDay(day: Day) -> UIViewController {
        
        let vc = storyboard?.instantiateViewControllerWithIdentifier("WeatherViewController") as! WeatherViewController
        let nav = UINavigationController(rootViewController: vc)
        vc.weather = data[day]
        
        return nav
    }

}

extension ViewController: UIPageViewControllerDataSource {
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let nav = viewController as? UINavigationController,
            viewController = nav.viewControllers.first as? WeatherViewController,
            day = viewController.weather?.day else {
                return nil
        }
        
        if day == .DayBeforeYesterday {
            return nil
        }
        
        guard let earlierDay = Day(rawValue: day.rawValue - 1) else {
            return nil
        }
        
        return self.weatherViewControllerForDay(earlierDay)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let nav = viewController as? UINavigationController,
            viewController = nav.viewControllers.first as? WeatherViewController,
            day = viewController.weather?.day else {
                return nil
        }
        
        if day == .DayAfterTomorrow {
            return nil
        }
        
        guard let laterDay = Day(rawValue: day.rawValue + 1) else {
            return nil
        }
        
        return self.weatherViewControllerForDay(laterDay)
    }
}

extension ViewController: WCSessionDelegate {
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        guard let dictionary = applicationContext[kWeatherResultsKey] as? [String: AnyObject] else {
            return
        }
        guard let date = applicationContext[kWeatherRequestDateKey] as? NSDate else {
            return
        }
        Weather.storeWeathersResult(dictionary, requestDate: date)
    }
}