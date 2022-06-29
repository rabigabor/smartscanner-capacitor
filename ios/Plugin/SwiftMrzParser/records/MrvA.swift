//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MrvA: MrzRecord{
    
    override init(_ format: MrzFormat){
        super.init(format)
        code1 = "V";
        code2 = "<";
        code = MrzDocumentCode.TypeV;
    }
    /**
     * Optional data at the discretion
    of the issuing State. May contain
    an extended document number
    as per 6.7, note (j).
     */
    public var optional: String = "";
    
    override public func fromMrz(_ mrz: String) throws {
        try super.fromMrz(mrz);
        let p = try MrzParser(mrz);
        setName(try p.parseName(try MrzRange(5, 44, 0)));
        validDocumentNumber = try p.checkDigit(9, 1, try MrzRange(0, 9, 1), "passport number");
        documentNumber = try p.parseString(try MrzRange(0, 9, 1));
        nationality = try p.parseString(try MrzRange(10, 13, 1));
        dateOfBirth = try p.parseDate(try MrzRange(13, 19, 1));
        validDateOfBirth = try p.checkDigit(19, 1, try MrzRange(13, 19, 1), "date of birth") && dateOfBirth.isDateValid();
        sex = try p.parseSex(20, 1);
        expirationDate = try p.parseDate(try MrzRange(21, 27, 1));
        validExpirationDate = try p.checkDigit(27, 1, try MrzRange(21, 27, 1), "expiration date") && expirationDate.isDateValid();
        optional = try p.parseString(try MrzRange(28, 44, 1));
        
        
    }

    override public func toString() -> String {
        return "MRV-A{" + super.toString() + ", optional=" + optional + "}";
    }

    override public func toMrz() throws -> String {
        var sb: String = ""
        
        sb.append(MrzParser.toMrz(issuingCountry, 3));
        sb.append(try MrzParser.nameToMrz(surname, givenNames, 39));
        sb.append("\n");
        // second line
        sb.append(MrzParser.toMrz(documentNumber, 9));
        sb.append(try MrzParser.computeCheckDigitChar(MrzParser.toMrz(documentNumber, 9)));
        sb.append(MrzParser.toMrz(nationality, 3));
        sb.append(dateOfBirth.toMrz());
        sb.append(try MrzParser.computeCheckDigitChar(dateOfBirth.toMrz()));
        sb.append(sex.rawValue);
        sb.append(expirationDate.toMrz());
        sb.append(try MrzParser.computeCheckDigitChar(expirationDate.toMrz()));
        sb.append(MrzParser.toMrz(optional, 16));
        sb.append("\n");
        
        return sb
    }
    
    
}
