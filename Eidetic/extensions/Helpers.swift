//
//  DateFormatter.swift
//  Eidetic
//
//  Created by user147964 on 12/28/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation
import UIKit
import Photos
//String checks
extension String {
    var hasAlphanumeric: Bool {
        return !isEmpty && range(of: "[a-zA-Z0-9]+", options: .regularExpression) != nil
    }
}

//Date Formatters
extension DateFormatter {
    
    convenience init (format: String) {
        self.init()
        dateFormat = format
        locale = Locale.current
    }
}

extension String {
    
    func toDate (format: String) -> Date? {
        return DateFormatter(format: format).date(from: self)
    }
    
    func toDateString (inputFormat: String, outputFormat:String) -> String? {
        if let date = toDate(format: inputFormat) {
            return DateFormatter(format: outputFormat).string(from: date)
        }
        return nil
    }
}

extension Date {
    
    func toString (format:String) -> String? {
        return DateFormatter(format: format).string(from: self)
    }
}

extension TimeInterval{
    
    func stringFromTimeInterval() -> String {
        
        let time = NSInteger(self)
        
//        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
//        let hours = (time / 3600)
        
//        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
        return String(format: "%0.2d:%0.2d",minutes,seconds)
        
    }
}
