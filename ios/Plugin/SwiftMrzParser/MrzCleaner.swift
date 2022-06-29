//
//  MrzCleaner.swift
//  Plugin
//
//  Created by rabigabor on 2021. 12. 07..
//  Copyright © 2021. Max Lynch. All rights reserved.
//

import Foundation


public class MrzCleaner{
    var previousMrzString: String?
    
    public func clean(_ mrz: String) throws -> String {
        var result: String = (
                mrz
                .replacingOccurrences(of: "^[^PIACV]*", with: "", options: .regularExpression, range: nil) // Remove everything before P, I, A or C
                .replacingOccurrences(of: "[ \\t\\r]+", with: "", options: .regularExpression, range: nil) // Remove any white space
                .replacingOccurrences(of: "\\n+", with: "\n", options: .regularExpression, range: nil) // Remove extra new lines
                .replacingOccurrences(of: "«", with: "<")
                .replacingOccurrences(of: "<c<", with: "<<<")
                .replacingOccurrences(of: "<e<", with: "<<<")
                .replacingOccurrences(of: "<E<", with: "<<<") // Good idea? Maybe not.
                .replacingOccurrences(of: "<K<", with: "<<<") // Good idea? Maybe not.
                .replacingOccurrences(of: "<S<", with: "<<<") // Good idea? Maybe not.
                .replacingOccurrences(of: "<C<", with: "<<<") // Good idea? Maybe not.
                .replacingOccurrences(of: "<¢<", with: "<<<")
                .replacingOccurrences(of: "<(<", with: "<<<")
                .replacingOccurrences(of: "<{<", with: "<<<")
                .replacingOccurrences(of: "<[<", with: "<<<")
                .replacingOccurrences(of: "^P[KC]", with: "P<", options: .regularExpression, range: nil)
                .replacingOccurrences(of: "[^A-Z0-9<\\n]", with: "", options: .regularExpression, range: nil)// Remove any other char
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
            if (result.contains("<") && (
                        result.hasPrefix("P") ||
                        result.hasPrefix("I") ||
                        result.hasPrefix("A") ||
                        result.hasPrefix("C") ||
                        result.hasPrefix("V"))
            ) {
                switch (result.indicesOf(string: "\n").count) {
                    case 1:
                        if (result.length > 89) {
                            result = result[0..<88]
                        }
                    case 2:
                        if (result.length > 92) {
                            result = result[0..<91]
                        }
                    default:
                        throw MrzError.IllegalArgument("Invalid MRZ string. Wrong number of lines.")
                }
            } else {
                throw MrzError.IllegalArgument("Invalid MRZ string. No '<' or 'P', 'I', 'A', 'C', 'V' detected.")
            }

            return result
        }

        func parseAndClean(_ mrz: String) throws -> MrzRecord {
            let record: MrzRecord = try MrzParser.parse(mrz)

            print("Previous Scan: \(previousMrzString)")
            if (record.validDateOfBirth && record.validDocumentNumber && record.validExpirationDate || record.validComposite) {
                record.givenNames = record.givenNames.replaceNumbertoChar()
                record.surname = record.surname.replaceNumbertoChar()
                record.issuingCountry = record.issuingCountry.replaceNumbertoChar()
                record.nationality = record.nationality.replaceNumbertoChar()
                return record
            } else {
                print("Still accept scanning.")
                if (mrz != previousMrzString) {
                    previousMrzString = mrz
                }
                throw MrzError.IllegalArgument("Invalid check digits.")
            }
        }
}
