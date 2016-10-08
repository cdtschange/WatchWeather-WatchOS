//
//  WeatherViewController.swift
//  WatchWeather
//
//  Created by Mao on 08/10/2016.
//  Copyright © 2016 pinteccdts. All rights reserved.
//

import UIKit
import WatchWeatherKit

class WeatherViewController: UIViewController {
    
    @IBOutlet weak var lowTemprature: UILabel!
    @IBOutlet weak var highTemprature: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    var weather: Weather? {
        didSet {
            title = weather?.day.title
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let weather = weather else { return }
        lowTemprature.text = "\(weather.lowTemperature)℃"
        highTemprature.text = "\(weather.highTemperature)℃"
        
        let imageName: String
        switch weather.state {
        case .Sunny: imageName = "sunny"
        case .Cloudy: imageName = "cloudy"
        case .Rain: imageName = "rain"
        case .Snow: imageName = "snow"
        }
        
        weatherImage.image = UIImage(named: imageName)
    }
}
