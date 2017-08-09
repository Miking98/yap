//
//  LocationManager.swift
//  accountabill
//
//  Created by Michael Wornow on 7/21/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import CoreLocation

class LocationManager {
    static let shared = CLLocationManager()
    
    private init() {
        LocationManager.shared.desiredAccuracy = kCLLocationAccuracyBest
    }
}
