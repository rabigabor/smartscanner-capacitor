//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MrtdTd1: MrzRecord{
    
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
    /**
     * optional (for U.S. passport holders, 21-29 may be corresponding passport number)
     */
    public var optional2: String = "";
    
    override public func fromMrz(_ mrz: String) throws {
        try super.fromMrz(mrz);
        let p = MrzParser(mrz);
        validDocumentNumber = p.checkDigit(14, 0, try MrzRange(5, 14, 0), "document number");
        documentNumber = p.parseString(try MrzRange(5, 14, 0));

        optional = p.parseString(try MrzRange(15, 30, 0));
        dateOfBirth = try p.parseDate(try MrzRange(0, 6, 1));
        validDateOfBirth = p.checkDigit(6, 1, try MrzRange(0, 6, 1), "date of birth") && dateOfBirth.isDateValid();
        sex = p.parseSex(7, 1);
        expirationDate = try p.parseDate(try MrzRange(8, 14, 1));
        validExpirationDate = p.checkDigit(14, 1, try MrzRange(8, 14, 1), "expiration date") && expirationDate.isDateValid();
        nationality = p.parseString(try MrzRange(15, 18, 1));
        optional2 = p.parseString(try MrzRange(18, 29, 1));
        validComposite = p.checkDigit(29, 1, p.rawValue([try MrzRange(5, 30, 0), try MrzRange(0, 7, 1), try MrzRange(8, 15, 1), try MrzRange(18, 29, 1)]), "mrz");
        setName(try p.parseName(try MrzRange(0, 30, 2)));
    }

    override public func toString() -> String {
        return "MRTD-TD1{" + super.toString() + ", optional=" + optional + ", optional2=" + optional2 + "}";
    }

    override public func toMrz() -> String {
        var sb: String = ""
        sb.append(code1);
        sb.append(code2);
        sb.append(MrzParser.toMrz(issuingCountry, 3));
        let dno = MrzParser.toMrz(documentNumber, 9) + MrzParser.computeCheckDigitChar(MrzParser.toMrz(documentNumber, 9)) + MrzParser.toMrz(optional, 15);
        sb.append(dno);
        sb.append("\n");
        // second line
        let dob = dateOfBirth.toMrz() + MrzParser.computeCheckDigitChar(dateOfBirth.toMrz());
        sb.append(dob);
        sb.append(sex.rawValue);
        let ed = expirationDate.toMrz() + MrzParser.computeCheckDigitChar(expirationDate.toMrz());
        sb.append(ed);
        sb.append(MrzParser.toMrz(nationality, 3));
        sb.append(MrzParser.toMrz(optional2, 11));
        sb.append(MrzParser.computeCheckDigitChar(dno + dob + ed + MrzParser.toMrz(optional2, 11)));
        sb.append("\n");
        // third line
        sb.append(try! MrzParser.nameToMrz(surname, givenNames, 30));
        sb.append("\n");
        return sb
    }



}
