//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MrtdTd2: MrzRecord{
    
    override init(_ format: MrzFormat){
        super.init(format)
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
        setName(try p.parseName(try MrzRange(5, 36, 0)));
        validDocumentNumber = try p.checkDigit(9, 1, try MrzRange(0, 9, 1), "document number");
        documentNumber = try p.parseString(try MrzRange(0, 9, 1));
        nationality = try p.parseString(try MrzRange(10, 13, 1));
        dateOfBirth = try p.parseDate(try MrzRange(13, 19, 1));
        validDateOfBirth = try p.checkDigit(19, 1, try MrzRange(13, 19, 1), "date of birth") && dateOfBirth.isDateValid();
        sex = try p.parseSex(20, 1);
        expirationDate = try p.parseDate(try MrzRange(21, 27, 1));
        validExpirationDate = try p.checkDigit(27, 1, try MrzRange(21, 27, 1), "expiration date") && expirationDate.isDateValid();
        optional = try p.parseString(try MrzRange(28, 35, 1));
        validComposite = try p.checkDigit(35, 1, p.rawValue([try MrzRange(0, 10, 1), try MrzRange(13, 20, 1), try MrzRange(21, 35, 1)]), "mrz");
            
        
    }

    override public func toString() -> String {
        return "MRTD-TD2{" + super.toString() + ", optional=" + optional + "}";
    }

    override public func toMrz() throws -> String {
        var sb: String = ""
        
        sb.append(code1);
        sb.append(code2);
        sb.append(MrzParser.toMrz(issuingCountry, 3));
        sb.append(try MrzParser.nameToMrz(surname, givenNames, 31));
        sb.append("\n");
        // second line
        let dn = MrzParser.toMrz(documentNumber, 9) + (try  MrzParser.computeCheckDigitChar(MrzParser.toMrz(documentNumber, 9)));
        sb.append(dn);
        sb.append(MrzParser.toMrz(nationality, 3));
        let dob = dateOfBirth.toMrz() + (try  MrzParser.computeCheckDigitChar(dateOfBirth.toMrz()));
        sb.append(dob);
        sb.append(sex.rawValue);
        let ed = expirationDate.toMrz() + (try  MrzParser.computeCheckDigitChar(expirationDate.toMrz()));
        sb.append(ed);
        sb.append(MrzParser.toMrz(optional, 7));
        sb.append(try MrzParser.computeCheckDigitChar(dn + dob + ed + (try MrzParser.toMrz(optional, 7))));
        sb.append("\n");
        
        return sb
    }
    
}
