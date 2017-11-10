//
//  Geofence.swift
//  GarageControl
//
//  Created by Mathieu Clement on 10/5/15.
//  Copyright © 2015 Mathieu Clement. All rights reserved.
//

import Foundation
import CoreLocation

class Geofence : NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    let region = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 46.712345, longitude: 7.123456),
        radius: CLLocationDistance.init(250), // m
        identifier: "Garage"
    )
    
    var onEnteringFunc : () -> Void
    var onExitingFunc : () -> Void
    
    init(onEntering:() -> Void, onExiting: () -> Void) {
        onEnteringFunc = onEntering
        onExitingFunc = onExiting
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestAlwaysAuthorization()
        
        region.notifyOnExit = true
        region.notifyOnEntry = true
    }
    
    func isReadyForMonitoring() -> Bool {
        return CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion)
            && CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways;
    }
    
    func startMonitoring() {
        assert(isReadyForMonitoring())
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringForRegion(region)
    }
    
    func stopMonitoring() {
        locationManager.stopMonitoringForRegion(region)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("on enter region")
        onEnteringFunc()
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("on exit region")
        onExitingFunc()
    }
    
    /*
    func locationManager(manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]) {
            print("Did update locations: \(locations)")
    }
    */
    
    func locationManager(manager: CLLocationManager,
        didFailWithError error: NSError) {
            print("Did fail with error: \(error.localizedDescription)" )
    }
    
    /*
    func locationManager(manager: CLLocationManager,
        didStartMonitoringForRegion region: CLRegion) {
            print("Did start monitoring for region")
            locationManager.requestStateForRegion(region)
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        print("Did determine state \(state) for region \(region)")
    }
    */
    
    
}
