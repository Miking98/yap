//
//  Base.swift
//  accountabill
//
//  Created by Michael Wornow on 7/24/17.
//  Copyright © 2017 Michael Wornow. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CoreLocation

class Base {
    
    // Date formatting
    func formatDateForPrint(date: Date?) -> String {
        if date == nil {
            return ""
        }
        // Returns date string in format: October 8, 2016 at 10:48:53 PM
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .long
        return formatter.string(from: date!)
    }
    func formatDateForFirebase(date: Date?) -> String {
        if date == nil {
            return ""
        }
        // Returns date string in format: October 8, 2016 at 10:48:53 PM
        let formatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        formatter.locale = enUSPosixLocale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter.string(from: date!)
    }
    func convertDateFromFirebaseToString(dateString: String?) -> Date {
        if dateString == nil {
            return Date()
        }
        // Returns date string in format: October 8, 2016 at 10:48:53 PM
        let formatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        formatter.locale = enUSPosixLocale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter.date(from: dateString!)!
    }
    static func convertDateFromFirebaseToString(dateString: String?) -> Date {
        if dateString == nil {
            return Date()
        }
        // Returns date string in format: October 8, 2016 at 10:48:53 PM
        let formatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        formatter.locale = enUSPosixLocale
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter.date(from: dateString!)!
    }

    
    // Location formating
    func formatLocationForPrint(location: CLLocation, completion: @escaping (_ location: String) -> Void) {
        var geoLocation = ""
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemarks = placemarks {
                if let placemark = placemarks.first {
                    if placemark.locality != nil {
                        geoLocation += placemark.locality!
                    }
                    if placemark.administrativeArea != nil {
                        geoLocation += " " + placemark.administrativeArea!
                        
                    }
                }
            }
            completion(geoLocation)
        }
    }
}
