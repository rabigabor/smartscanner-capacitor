//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MrzRecord: CustomStringConvertible{
    
    /**
     * The document code.
     */
    public var code: MrzDocumentCode = MrzDocumentCode.Passport;
    /**
     * Document code, see {@link MrzDocumentCode} for details on allowed values.
     */
    public var code1: String = "";
    /**
     * For MRTD: Type, at discretion of states, but 1-2 should be IP for passport card, AC for crew member and IV is not allowed.
     * For MRP: Type (for countries that distinguish between different types of passports)
     */
    public var code2: String = "";


    public var issuingCountry: String = "";
    /**
     * Document number, e.g. passport number.
     */
    public var documentNumber: String = "";
    /**
     * The surname in uppercase.
     */
    public var surname: String = "";
    /**
     * The given names in uppercase, separated by spaces.
     */
    public var givenNames: String = "";
    /**
     * Date of birth.
     */
    public var dateOfBirth: MrzDate = MrzDate(1970,1,1)
    /**
     * Sex
     */
    public var sex: MrzSex = MrzSex.Unspecified;
    /**
     * expiration date of passport
     */
    public var expirationDate: MrzDate = MrzDate(1970,1,1);
    /**
     * An <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3">ISO 3166-1 alpha-3</a> country code of nationality.
     * See {@link #issuingCountry} for additional allowed values.
     */
    public var nationality: String = "";
    /**
     * Detected MRZ format.
     */
    public final var format: MrzFormat;


    /**
     * check digits, usually common in every document.
     */
    public var validDocumentNumber: Bool = true;
    public var validDateOfBirth: Bool = true;
    public var validExpirationDate: Bool = true;
    public var validComposite: Bool = true;


    init(_ format: MrzFormat) {
        self.format = format;
    }

    public func toString() -> String{
        return "MrzRecord{code=\(code)[\(code1)\(code2)], issuingCountry=\(issuingCountry), documentNumber=\(documentNumber), surname=\(surname), givenNames=\(givenNames), dateOfBirth=\(dateOfBirth), sex=\(sex), expirationDate=\(expirationDate), nationality=\(nationality)}";
    }
    public var description: String {
        return self.toString()
    }

    /**
     * Parses the MRZ record.
     * @param mrz the mrz record, not null, separated by \n
     * @throws MrzParseException when a problem occurs.
     */
    public func fromMrz(_ mrz: String) throws {
        if (self.format != (try MrzFormat.get(mrz))) {
            throw MrzError.ParseException("invalid format: \((try MrzFormat.get(mrz)))", mrz, try MrzRange(0, 0, 0), format);
        }
        code = try MrzDocumentCode.parse(mrz);
        code1 = mrz[0];
        code2 = mrz[1];
        issuingCountry = try MrzParser(mrz).parseString(try MrzRange(2, 5, 0));
    }
    
    /**
     * Helper method to set the full name. Changes both {@link #surname} and {@link #givenNames}.
     * @param name expected array of length 2, in the form of [surname, first_name]. Must not be null.
     */
    public func setName(_ name: [String]) {
        self.surname = name[0];
        self.givenNames = name[1];
    }
    
    /**
     * Serializes this record to a valid MRZ record.
     * @return a valid MRZ record, not null, separated by \n
     */
    public func toMrz() throws -> String{
        fatalError("Not implemented error")
    };
}
