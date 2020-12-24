//
//  LocationService.swift
//  socialApp
//
//  Created by Денис Щиголев on 06.10.2020.
//  Copyright © 2020 Денис Щиголев. All rights reserved.
//

import MapKit
import FirebaseAuth
import CoreLocation

class LocationService: UIResponder {
    
    static let shared = LocationService()
    
    private var userID: String?
    private let locationManager = CLLocationManager()
    
    func getCoordinate(userID: String, virtualLocation: MVirtualLocation, complition:@escaping(Bool)->Void) {
        
        switch virtualLocation {
        //get current location and save
        case .current:
            self.userID = userID
            locationManager.delegate = self
            
            let authorizationStatus = CLLocationManager.authorizationStatus()
            
            switch authorizationStatus {
            case .authorizedWhenInUse:
                locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
                locationManager.requestLocation()
                complition(true)
                
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                complition(true)
                
            case .restricted:
                locationManager.requestWhenInUseAuthorization()
                complition(true)
                
            case .denied:
                //show alert and go to system settings to change geo settings for app
                complition(false)
            default:
                locationManager.requestWhenInUseAuthorization()
                complition(true)
            }
            //save default location forPlay
        case .forPlay:
            guard let forPlayLongitude = MVirtualLocation.forPlay.defaultValue[MLocation.longitude.rawValue] else { return }
            guard let forPlayLatitude = MVirtualLocation.forPlay.defaultValue[MLocation.latitude.rawValue] else { return }
            let location = CLLocationCoordinate2D(latitude: forPlayLatitude, longitude: forPlayLongitude)
            FirestoreService.shared.saveLocation(userID: userID,
                                                 longitude: location.longitude,
                                                 latitude: location.latitude) { result in
                switch result {
                
                case .success(_):
                    var people = UserDefaultsService.shared.getMpeople()
                    people?.location = location
                    UserDefaultsService.shared.saveMpeople(people: people)
                    complition(true)
                case .failure(let error):
                    fatalError(error.localizedDescription)
                }
            }
        }
    }
    
    func checkLocationIsDenied() -> Bool{
        let authorizationStatus = CLLocationManager.authorizationStatus()
        switch authorizationStatus {
        case .denied:
            return true
        default:
            return false
        }
    }
    
    func getDistance(currentPeople:MPeople, newPeople: MPeople) -> Int {
        let currentCoordinate = CLLocation(latitude: currentPeople.location.latitude,
                                           longitude: currentPeople.location.longitude)
        let peopleCoordinate = CLLocation(latitude: newPeople.location.latitude,
                                          longitude: newPeople.location.longitude)
        
        return Int(currentCoordinate.distance(from: peopleCoordinate) / 1000)
    }
}

//MARK: CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let coordinate = location.coordinate
            guard let userID = userID else { fatalError("Cant get userID for location")}
            FirestoreService.shared.saveLocation(userID: userID,
                                                 longitude: coordinate.longitude,
                                                 latitude: coordinate.latitude) { result in
                switch result {
                
                case .success(_):
                    NotificationCenter.postCoordinatesIsUpdate()
                case .failure(let error):
                    PopUpService.shared.showInfo(text: "Ошибка: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        
        case .authorizedAlways:
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
        case .authorizedWhenInUse:
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.requestLocation()
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if (authorizationStatus == CLAuthorizationStatus.notDetermined) {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}
