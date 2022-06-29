//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public enum MrzError: Error{
    case InvalidMrzSexChar(String)
    case ParseException(String, String, MrzRange, MrzFormat?)
    case IllegalArgument(String)
    case RuntimeException(String)
}
