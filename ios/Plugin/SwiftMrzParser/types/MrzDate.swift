//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MrzDate: Equatable, Comparable, CustomStringConvertible {

    /**
     * Year, 00-99.
     * <p/>
     * Note: I am unable to find a specification of conversion of this value to a full year value.
     */
    public final var year: Int;
    /**
     * Month, 1-12.
     */
    public final var month: Int;
    /**
     * Day, 1-31.
     */
    public final var day: Int;
    
    public final var mrz: String;


    init(_ year: Int, _ month: Int, _ day: Int){
        
        self.year = year
        self.month = month;
        self.day = day;
        self.mrz = "";
    }
    init(_ year: Int, _ month: Int, _ day: Int, _ raw: String){
        
        self.year = year
        self.month = month;
        self.day = day;
        self.mrz = raw;
    }

    public func toString() -> String{
        return "{\(day)/\(month)/\(year)}";
    }
    public func toStringNormal() -> String{
        var yearFull: Int = year;
        print("yearRR \((yearFull+100)) \((Calendar.current.component(.year, from: Date()) ))")
        if ((yearFull+2000) > (Calendar.current.component(.year, from: Date()) + 5)){
            yearFull += 1900;
        } else {
            yearFull += 2000;
        }
        
        return "\(day)/\(month)/\(yearFull)";
    }
    public var description: String {
        return "{\(day)/\(month)/\(year)}";
    }

    public func toMrz() -> String {
        if(mrz != "") {
            return mrz;
        } else {
            return String(format:"%02d%02d%02d", year, month, day);
        }
    }

    private func check() -> Bool {
        if (year < 0 || year > 99) {
            print("Parameter year: invalid value \(year): must be 0..99");
            return false;
        }
        if (month < 1 || month > 12) {
            print("Parameter month: invalid value \(month): must be 1..12");
            return false;
        }
        if (day < 1 || day > 31) {
            print("Parameter day: invalid value \(day): must be 1..31");
            return false;
        }

        return true;
    }
    
    public static func ==(lhs: MrzDate, rhs: MrzDate) -> Bool {
        return lhs.year == rhs.year && lhs.month == rhs.month && lhs.day == rhs.day
    }
    
    public static func <(lhs: MrzDate, rhs: MrzDate) -> Bool {
        return (lhs.year*10000 + lhs.month*100 + lhs.day) < (rhs.year*10000 + rhs.month*100 + rhs.day)
    }


    /**
     * Returns the date validity
     * @return Returns a boolean true if the parsed date is valid, false otherwise
     */
    public func isDateValid() -> Bool {
        return self.check();
    }
}
