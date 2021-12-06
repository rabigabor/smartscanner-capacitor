//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MRP: MrzRecord{
    
    override init(_ format: MrzFormat){
        super.init(format)
    }

    /**
     * personal number (may be used by the issuing country as it desires), 14 characters long.
     */
    public var personalNumber: String = "";

    public var validPersonalNumber: Bool = false;

    
    override public func fromMrz(_ mrz: String) throws {
        try super.fromMrz(mrz);
        let parser = MrzParser(mrz);
        setName(try parser.parseName(try MrzRange(5, 44, 0)));
        validDocumentNumber = parser.checkDigit(9, 1, try MrzRange(0, 9, 1), "passport number");
        documentNumber = parser.parseString(try MrzRange(0, 9, 1));

        nationality = parser.parseString(try MrzRange(10, 13, 1));
        dateOfBirth = try parser.parseDate(try MrzRange(13, 19, 1));
        validDateOfBirth = parser.checkDigit(19, 1, try MrzRange(13, 19, 1), "date of birth") && dateOfBirth.isDateValid();
        sex = parser.parseSex(20, 1);
        expirationDate = try parser.parseDate(try MrzRange(21, 27, 1));
        validExpirationDate = parser.checkDigit(27, 1, try MrzRange(21, 27, 1), "expiration date") && expirationDate.isDateValid();
        personalNumber = parser.parseString(try MrzRange(28, 42, 1));
        validPersonalNumber = parser.checkDigit(42, 1, try MrzRange(28, 42, 1), "personal number");
        validComposite = parser.checkDigit(43, 1, parser.rawValue([try MrzRange(0, 10, 1), try MrzRange(13, 20, 1), try MrzRange(21, 43, 1)]), "mrz");
    }

    override public func toString() -> String {
        return "MRP{" + super.toString() + ", personalNumber=" + personalNumber + "}";
    }

    override public func toMrz() -> String {
        // first line
        var sb: String = "";
        sb.append(code1);
        sb.append(code2);
        sb.append(MrzParser.toMrz(issuingCountry, 3));
        sb.append(try! MrzParser.nameToMrz(surname, givenNames, 39));
        sb.append("\n");
        // second line
        let docNum = MrzParser.toMrz(documentNumber, 9) + MrzParser.computeCheckDigitChar(MrzParser.toMrz(documentNumber, 9));
        sb.append(docNum);
        sb.append(MrzParser.toMrz(nationality, 3));
        let dob = dateOfBirth.toMrz() + MrzParser.computeCheckDigitChar(dateOfBirth.toMrz());
        sb.append(dob);
        sb.append(sex.rawValue);
        let edpn = expirationDate.toMrz() + MrzParser.computeCheckDigitChar(expirationDate.toMrz()) + MrzParser.toMrz(personalNumber, 14) + MrzParser.computeCheckDigitChar(MrzParser.toMrz(personalNumber, 14));
        sb.append(edpn);
        sb.append(MrzParser.computeCheckDigitChar(docNum + dob + edpn));
        sb.append("\n");
        return sb
    }
}
