//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation


public enum MrzDocumentCode {
    /**
     * A passport, P or IP.
     * ... maybe Travel Document that is very similar to the passport.
     */
    case Passport
    /**
     * General I type (besides IP).
     */
    case TypeI
    /**
     * General A type (besides AC).
     */
    case TypeA
    /**
     * Crew member (AC).
     */
    case CrewMember
    /**
     * General type C.
     */
    case TypeC
    /**
     * Type V (Visa).
     */
    case TypeV
    /**
     *
     */
    case Migrant

    /**
     * @author Zsombor
     * turning to switch statement due to lots of types
     *
     * @param mrz string
     */
    static func parse(_ mrz: String) throws -> MrzDocumentCode {
        let code = mrz[0..<2];

        // 2-letter checks
        switch code{
            case "IV":
                throw MrzError.ParseException("IV document code is not allowed", mrz, try! MrzRange(0, 2, 0), nil)
        case "AC": return .CrewMember;
        case "ME": return .Migrant;
        case "TD": return .Migrant; // travel document
        case "IP": return .Passport;
        default: break;
        }

        // 1-letter checks
        switch code[0]{
        case "T": return .Passport; // usually Travel Document
        case "P": return .Passport;
        case "A": return .TypeA;
        case "C": return .TypeC;
        case "V": return .TypeV;
        case "I": return .TypeI; // identity card or residence permit
        case "R": return .Migrant; // swedish '51 Convention Travel Document
        default: break;
        }


        throw MrzError.ParseException("Unsupported document code: " + code, mrz, try! MrzRange(0, 2, 0), nil);
    }
}
