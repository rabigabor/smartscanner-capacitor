//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation
public enum MrzSex: String {

    case Male = "M"
    case Female = "F"
    case Unspecified = "X"
    
    init(_ mrz: String) {
        switch mrz.uppercased() {
            case "M": self = .Male
            case "F": self = .Female
            default: self = .Unspecified
        }
    }
    
    static func fromMrz(_ sex: String) throws -> MrzSex {
        switch sex {
            case "M":
                return .Male;
            case "F":
                return .Female;
            case "<":
                return .Unspecified
            case "X":
                return .Unspecified;
            default:
                throw MrzError.InvalidMrzSexChar("Invalid MRZ sex character: " + sex);
        }
    }
}
