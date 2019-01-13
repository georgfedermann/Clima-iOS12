//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import Alamofire;
import SwiftyJSON;
import UIKit;
import CoreLocation;


class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL:String = "https://api.openweathermap.org/data/2.5/weather"
    let APP_ID:String = "e72ca729af228beabd5d20e3b7749713"
    /***Get your own App ID at https://openweathermap.org/appid ****/
    
    
    //TODO: Declare instance variables here
    let locationManager:CLLocationManager = CLLocationManager();
    let weatherDataModel:WeatherDataModel = WeatherDataModel();
    
    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: Set up the location manager here.
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestAlwaysAuthorization();
        // actually tap into location manager
        locationManager.startUpdatingLocation(); // asynchronous method
    }
    
    
    
    //MARK: - Networking
    /***************************************************************/
    //Write the getWeatherData method here:
    func getWeatherData(url:String, parameters:[String:String]){
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            // networking is happening in an asynchronous method
            // thus provide a closure to be executed when the response comes back.
            response in
            if response.result.isSuccess {
                print("AlamoFire request to weather data svc was successful.");
                let weatherJson:JSON = JSON(response.result.value!);
                print(weatherJson);
                self.updateWeatherData(json:weatherJson);
            } else {
                print("Error \(response.result.error!)");
                self.cityLabel.text = "Connection Issues ...";
            }
        }
    }
    
    //MARK: - JSON Parsing
    /***************************************************************/
    //Write the updateWeatherData method here:
    func updateWeatherData(json:JSON){
        if let currentTemperature:Double = json["main"]["temp"].double {
            weatherDataModel.temperature = Int(currentTemperature - 273.15);
            weatherDataModel.city = json["name"].stringValue == "Gemeindebezirk Innere Stadt" ? "Wien" : json["name"].stringValue;
            weatherDataModel.condition = json["weather"][0]["id"].intValue;
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition:weatherDataModel.condition);
            updateUiWithWeatherData();
        } else {
            cityLabel.text = "Weather data unavailable ...";
        }
    }
    
    
    
    
    //MARK: - UI Updates
    /***************************************************************/
    
    
    //Write the updateUIWithWeatherData method here:
    func updateUiWithWeatherData() {
        print("updateUiWithWeatherData()-> set cityLabel to \(weatherDataModel.city), set temperatureLabel to \(weatherDataModel.temperature), set weatherIcon to \(weatherDataModel.weatherIconName).");
        cityLabel.text = weatherDataModel.city;
        temperatureLabel.text = "\(weatherDataModel.temperature) °";
        weatherIcon.image = UIImage(named:weatherDataModel.weatherIconName);
    }
    
    
    
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here:
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        // the location manager sends an array of location measure points with typically
        // the accuracy increasing with time. Thus, the last point will be the
        // one we go for.
        let location:CLLocation = locations[locations.count - 1];
        // check whether the locations are valid. LocationManager will use a
        // negative property value for horizontalAccuracy to signal that the
        // location is invalid.
        if location.horizontalAccuracy > 0 {
            // now we are happy with a valid result
            locationManager.stopUpdatingLocation();
            // after stopping the location update mechanism, locationManager might
            // still call the delegate again while it's in the process of being stopped ...
            // so, to not waste calls to the weatcher service API remove the delegate
            // from the locationManager so it won't be able to call the delegate
            // method stack any more:
            locationManager.delegate = nil;
            let latitude = location.coordinate.latitude;
            let longitude = location.coordinate.longitude;
            print("longitude = \(longitude), latitude = \(latitude).");
            let params:[String:String] = ["lat":String(latitude), "lon":String(longitude), "appid": APP_ID];
            
            getWeatherData(url: WEATHER_URL, parameters: params);
        }
    }
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error);
        cityLabel.text = "Location Unavailable";
    }

    //MARK: - Change City Delegate methods
    /***************************************************************/

    //Write the userEnteredANewCityName Delegate method here:
    func userEnteredNewCityName(city: String) {
        let params:[String:String] = ["q":city, "appid":APP_ID];
        getWeatherData(url: WEATHER_URL, parameters: params);
    }

    //Write the PrepareForSegue Method here
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let destinationViewController:ChangeCityViewController = segue.destination as! ChangeCityViewController;
            destinationViewController.delegate = self;
        }
    }
    
}


