//
//  DateFormatter.swift
//  Eidetic
//
//  Created by user147964 on 12/28/18.
//  Copyright © 2018 user145467. All rights reserved.
//

import Foundation
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
