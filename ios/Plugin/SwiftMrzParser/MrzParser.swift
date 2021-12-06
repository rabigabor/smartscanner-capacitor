//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MrzParser{
    /**
     * The MRZ record, not null.
     */
    public var mrz: String;
    /**
     * The MRZ record separated into rows.
     */
    public var rows: [String];
    /**
     * MRZ record format.
     */
    public final var format: MrzFormat;

    /**
     * Creates new parser which parses given MRZ record.
     * @param mrz the MRZ record, not null.
     */
    init(_ mrz: String) {
        self.mrz = mrz;
        self.rows = mrz.components(separatedBy: "\n");
        self.format = try! MrzFormat.get(mrz);
    }

    /**
     * @author jllarraz@github
     * Parses the MRZ name in form of SURNAME<<FIRSTNAME<
     * @param range the range
     * @return array of [surname, first_name], never null, always with a length of 2.
     */
    public func parseName(_ range: MrzRange) throws -> [String] {
        try checkValidCharacters(range);
        var str: String = rawValue([range]);
        // Workaround: MLKIT sometimes reads *character `<` as either `S, C, E or K`
        // To make sure that it is not part of the name string checks begin with `<<(*)`
        // assuming that a person"s name cannot have multiple different surnames.
        // Filed this issue in MLKit github: https://github.com/googlesamples/mlkit/issues/354
        while (str.hasSuffix("<") ||
                str.hasSuffix("<<S") || // Sometimes MLKit perceives `<` as `S`
                str.hasSuffix("<<E") || // Sometimes MLKit perceives `<` as `E`
                str.hasSuffix("<<C") || // Sometimes MLKit perceives `<` as `C`
                str.hasSuffix("<<K") || // Sometimes MLKit  perceives `<` as `K`
                str.hasSuffix("<<KK") ) // Sometimes MLKit  perceives `<<` as `KK`
        {
            str = str[0..<(str.length-1)];
        }

        let names: [String] = str.components(separatedBy: "<<");
        var surname: String;
        var givenNames: String = "";
        surname = parseString(try MrzRange(range.column, range.column + names[0].length, range.row));
        if (names.count == 1){
            givenNames = parseNameString(try MrzRange(range.column, range.column + names[0].length, range.row));
            surname = "";
        }
        else if (names.count > 1){
            surname = parseNameString(try MrzRange(range.column, range.column + names[0].length, range.row));
            givenNames = parseNameString(try MrzRange(range.column + names[0].length + 2, range.column + str.length, range.row));
        }
        return [surname, givenNames];
    }

    /**
     * Returns a raw MRZ value from given range. If multiple ranges are specified, the value is concatenated.
     * @param range the ranges, not null.
     * @return raw value, never null, may be empty.
     */
    public func rawValue(_ range: [MrzRange]) -> String {
        var sb:String = "";
        for r in range {
            sb.append(rows[r.row][r.column..<r.columnTo]);
        }
        return sb;
    }

    /**
     * Checks that given range contains valid characters.
     * @param range the range to check.
     */
    public func checkValidCharacters(_ range: MrzRange) throws {
        let str: String = rawValue([range]);
        for i in 0...str.length {
            let c: String =  str[i];
            if (c != MrzParser.FILLER && (c < "0" || c > "9") && (c < "A" || c > "Z")) {
                throw MrzError.ParseException("Invalid character in MRZ record: " + c, mrz, try MrzRange(range.column + i, range.column + i + 1, range.row), format);
            }
        }
    }

    /**
     * Parses a string in given range. &lt;&lt; are replaced with ", ", &lt; is replaced by space.
     * @param range the range
     * @return parsed string.
     */
    public func parseString(_ range: MrzRange) -> String {
        try! checkValidCharacters(range);
        var str: String = rawValue([range]);
        while str.hasSuffix("<") {
            str = str[0..<(str.length-1)];
        }
        return str.replacingOccurrences(of: MrzParser.FILLER + MrzParser.FILLER, with:", ").replacingOccurrences(of:MrzParser.FILLER, with:" ");
    }

    /**
     * Parses a string in given range. and known characters will be replaced to numbers
     *  &lt;&lt; are replaced with ", ", &lt; is replaced by space.
     * @param range the range
     * @return parsed string.
     */
    public func parseNumberString(_ range: MrzRange) -> String {
        try! checkValidCharacters(range);
        var str: String = (rawValue([range])
                            .replacingOccurrences(of: "O", with: "0")
                            .replacingOccurrences(of: "I", with:"1")
                            .replacingOccurrences(of: "B", with:"8")
                            .replacingOccurrences(of: "S", with:"5")
                            .replacingOccurrences(of: "Z", with:"2")
        );
        while str.hasSuffix("<") {
            str = str[0..<(str.length-1)];
        }
        return str.replacingOccurrences(of: "<", with:"").replacingOccurrences(of: MrzParser.FILLER + MrzParser.FILLER, with:", ").replacingOccurrences(of:MrzParser.FILLER, with:" ");
    }

    /**
     * Parses a string in given range for MRZ names. &lt;&lt; are replaced with  "",
     * &lt; is replaced by space.
     * @param range the range
     * @return parsed string.
     */
    public func parseNameString(_ range: MrzRange) -> String {
        try! checkValidCharacters(range);
        var str: String = rawValue([range]);
        while (str.hasSuffix("<") ||
                str.hasSuffix("<<S") || // Sometimes MLKit perceives `<` as `S`
                str.hasSuffix("<<E") || // Sometimes MLKit perceives `<` as `E`
                str.hasSuffix("<<C") || // Sometimes MLKit perceives `<` as `C`
                str.hasSuffix("<<K") || // Sometimes MLKit perceives `<` as `K`
                str.hasSuffix("<<KK") ) // Sometimes MLKit perceives `<<` as `KK`
        {
            str = str[0..<(str.length-1)];
        }
        return str.replacingOccurrences(of: MrzParser.FILLER + MrzParser.FILLER, with:"").replacingOccurrences(of:MrzParser.FILLER, with:" ");

    }

    /**
     * Parses a string in given range for MRZ names. &lt;&lt; are replaced with  "",
     * &lt; is replaced by space.
     * @param range the range
     * @return parsed string.
     */
    public func parseNameStringWithSeparators(_ range: MrzRange) -> String {
        try! checkValidCharacters(range);
        var str: String = rawValue([range]);
        while (str.hasSuffix("<") ||
                str.hasSuffix("<<S") || // Sometimes MLKit perceives `<` as `S`
                str.hasSuffix("<<E") || // Sometimes MLKit perceives `<` as `E`
                str.hasSuffix("<<C") || // Sometimes MLKit perceives `<` as `C`
                str.hasSuffix("<<CC") || // Sometimes MLKit perceives `<` as `C`
                str.hasSuffix("<<K") || // Sometimes MLKit perceives `<` as `K`
                str.hasSuffix("<<KK") || // Sometimes MLKit perceives `<<` as `KK`
                str.hasSuffix("<<KKK") || // Sometimes MLKit perceives `<<` as `KKK`
                str.hasSuffix("<<KKKK") || // Sometimes MLKit perceives `<<` as `KKKK`
                str.hasSuffix("<<KKKKK") ) // Sometimes MLKit perceives `<<` as `KKKKK`
        {
            str = str[0..<(str.length-1)];
        }
        return str.replacingOccurrences(of: MrzParser.FILLER + MrzParser.FILLER, with:", ").replacingOccurrences(of:MrzParser.FILLER, with:" ");
    }

    /**
     * Parses a document number string in given range, &lt;&lt; are replaced with "-",
     * &lt; is replaced by space.
     *
     * @param range the range
     * @return parsed string.
     */
    public func parseDocuString(_ range: MrzRange) -> String {
        try! checkValidCharacters(range);
        var str: String = rawValue([range]);
        while str.hasSuffix("<") {
            str = str[0..<(str.length-1)];
        }
        return str.replacingOccurrences(of: MrzParser.FILLER + MrzParser.FILLER, with:"-").replacingOccurrences(of:MrzParser.FILLER, with:" ");
    }

    /**
     * Verifies the check digit.
     * @param col the 0-based column of the check digit.
     * @param row the 0-based column of the check digit.
     * @param strRange the range for which the check digit is computed.
     * @param fieldName (optional) field name. Used only when validity check fails.
     * @return true if check digit is valid, false if not
     */
    public func checkDigit(_ col: Int, _ row: Int, _ strRange: MrzRange, _ fieldName: String) -> Bool {
        return checkDigit(col, row, rawValue([strRange]), fieldName);
    }

    /**
     * Verifies the check digit.
     * @param col the 0-based column of the check digit.
     * @param row the 0-based column of the check digit.
     * @param strRange the range for which the check digit is computed.
     * @param fieldName (optional) field name. Used only when validity check fails.
     * @return true if check digit is valid, false if not
     */
    public func checkDigitWithoutFiller(_ col: Int, _ row: Int, _ strRange: MrzRange, _ fieldName: String) -> Bool {
        return checkDigit(col, row, rawValue([strRange]).replacingOccurrences(of:"<", with:""), fieldName);
    }

    /**
     * Verifies the check digit.
     * @param col the 0-based column of the check digit.
     * @param row the 0-based column of the check digit.
     * @param str the raw MRZ substring.
     * @param fieldName (optional) field name. Used only when validity check fails.
     * @return true if check digit is valid, false if not
     */
    public func checkDigit(_ col: Int, _ row: Int, _ str: String, _ fieldName: String) -> Bool {

        /*
         * If the check digit validation fails, this will contain the location.
         */

        let digit: String = MrzParser.computeCheckDigit(str)
        var checkDigit: String = rows[row][col];
        if ((checkDigit == MrzParser.FILLER) || (checkDigit == "O")) {
            checkDigit = "0";
        }
        print("PARSER","checkDigit |"+digit+"|"+checkDigit+"|"+fieldName+"|"+str);
        if((fieldName==("document number") || fieldName==("passport number")) && (digit != checkDigit)){


            let guess0: Character = "0"
            let guessO: Character = "O"
            var occurences: [Int] = str.indicesOf(string: String(guess0)) + str.indicesOf(string: String(guessO))
            
            occurences.sort()
            

            var lists: [[Character]] = []
            for _ in 0...occurences.count{
                lists.append([guess0, guessO])
            }
            let products: [[Character]] = cartesianProduct(lists);
            print("PARSER", "occurences ", occurences);
            print("PARSER", "products ", products);

            for product in products{
                var newDocumentNumber = Array(str);
                for j in 0...product.count{
                    newDocumentNumber[occurences[j]] = product[j];
                }
                let newDocumentNumberStr = String(newDocumentNumber)
                let newDigit: String = MrzParser.computeCheckDigit(newDocumentNumberStr)
                print("PARSER","checkDigitNew |\(fieldName)|\(checkDigit)|\(newDigit)|\(newDocumentNumberStr)|\((newDigit==checkDigit))");
                if(newDigit == checkDigit) {
                    print("SmartScanner", "REPLACING \(str) to \(newDocumentNumberStr)");

                    mrz = mrz.replacingOccurrences(of: str, with: newDocumentNumberStr);
                    rows = mrz.components(separatedBy: "\n");

                    return true;
                }

            }
        }

        if (digit != checkDigit) {
            print("Check digit verification failed for \(fieldName): expected \(digit) but got \(checkDigit)")
            return false
        }
        return true;
    }


    /**
     * Parses MRZ date.
     * @param range the range containing the date, in the YYMMDD format. The range must be 6 characters long.
     * @return parsed date
     * @throws IllegalArgumentException if the range is not 6 characters long.
     */
    public func parseDate(_ range: MrzRange) throws -> MrzDate {
        if (range.length() != 6) {
            throw MrzError.IllegalArgument("Parameter range: invalid value " + range.toString() + ": must be 6 characters long");
        }
        var r: MrzRange;
        
        r = try MrzRange(range.column, range.column + 2, range.row);
        let year: Int = Int(rawValue([r])) ?? -1
        if (year < 0 || year > 99) {
            print("Invalid year value \(year): must be 0..99")
        }
        
        r = try  MrzRange(range.column + 2, range.column + 4, range.row);
        let month: Int = Int(rawValue([r])) ?? -1
        if (month < 1 || month > 12) {
            print("Invalid month value \(year): must be 1..12")
        }
        
        r = try MrzRange(range.column + 4, range.column + 6, range.row);
        let day: Int = Int(rawValue([r])) ?? -1
        if (day < 1 || day > 31) {
            print("Invalid day value \(year): must be 1..31")
        }
        
        return MrzDate(year, month, day, rawValue([range]));
    }

    /**
     * Parses the "sex" value from given column/row.
     * @param col the 0-based column
     * @param row the 0-based row
     * @return sex, never null.
     */
    public func parseSex(_ col: Int, _ row: Int) -> MrzSex {
        return try! MrzSex.fromMrz(rows[row][col]);
    }
    private static var MRZ_WEIGHTS: [Int] = [7, 3, 1];

    /**
     * Checks if given character is valid in MRZ.
     * @param c the character.
     * @return true if the character is valid, false otherwise.
     */
    private static func isValid(_ c: String) -> Bool{
        return ((c == MrzParser.FILLER) || (c >= "0" && c <= "9") || (c >= "A" && c <= "Z"));
    }

    private static func getCharacterValue(_ c: Character) throws -> Int {
        if (c == FILLER_CHAR) {
            return 0;
        }
        if (c >= "0" && c <= "9") {
            return Int((c.asciiValue ?? 0) - (Character("0").asciiValue ?? 0));
        }
        if (c >= "A" && c <= "Z") {
            return Int((c.asciiValue ?? 0) - (Character("A").asciiValue ?? 0) + 10);
        }
        throw MrzError.RuntimeException("Invalid character in MRZ record: \(c)");
    }

    /**
     * Computes MRZ check digit for given string of characters.
     * @param str the string
     * @return check digit in range of 0..9, inclusive. See <a href="http://www2.icao.int/en/MRTD/Downloads/Doc%209303/Doc%209303%20English/Doc%209303%20Part%203%20Vol%201.pdf">MRTD documentation</a> part 15 for details.
     */
    public static func computeCheckDigit(_ str: String) -> String {
        var result: Int = 0;
        var i: Int = 0;
        for c in str{
            result += (try! getCharacterValue(c)) * MrzParser.MRZ_WEIGHTS[i % MrzParser.MRZ_WEIGHTS.count];
            i += 1
        }
        return String(result % 10);
    }

    /**
     * Computes MRZ check digit for given string of characters.
     * @param str the string
     * @return check digit in range of 0..9, inclusive. See <a href="http://www2.icao.int/en/MRTD/Downloads/Doc%209303/Doc%209303%20English/Doc%209303%20Part%203%20Vol%201.pdf">MRTD documentation</a> part 15 for details.
     */
    public static func computeCheckDigitChar(_ str: String) -> String{
        return computeCheckDigit(str);
    }

    /**
     * Factory method, which parses the MRZ and returns appropriate record class.
     * @param mrz MRZ to parse.
     * @return record class.
     */
    public static func parse(_ mrz: String) -> MrzRecord {
        let result: MrzRecord = try! MrzFormat.get(mrz).newRecord();
        print("MRZRECORD TYPE",result.toString());
        try! result.fromMrz(mrz);
        return result;
    }



    private static var EXPAND_CHARACTERS: Dictionary<String, String> = [
        "\u{00C4}": "AE", // Ä
        "\u{00E4}": "AE", // ä
        "\u{00C5}": "AA", // Å
        "\u{00E5}": "AA", // å
        "\u{00C6}": "AE", // Æ
        "\u{00E6}": "AE", // æ
        "\u{0132}": "IJ", // Ĳ
        "\u{0133}": "IJ", // ĳ
        "\u{00D6}": "OE", // Ö
        "\u{00F6}": "OE", // ö
        "\u{00D8}": "OE", // Ø
        "\u{00F8}": "OE", // ø
        "\u{00DC}": "UE", // Ü
        "\u{00FC}": "UE", // ü
        "\u{00DF}": "SS", // ß
    ]

    /**
     * Converts given string to a MRZ string: removes all accents, converts the string to upper-case and replaces all spaces and invalid characters with "&lt;".
     * <p/>
     * Several characters are expanded:
     * <table border="1">
     * <tr><th>Character</th><th>Expand to</th></tr>
     * <tr><td>Ä</td><td>AE</td></tr>
     * <tr><td>Å</td><td>AA</td></tr>
     * <tr><td>Æ</td><td>AE</td></tr>
     * <tr><td>Ĳ</td><td>IJ</td></tr>
     * <tr><td>IJ</td><td>IJ</td></tr>
     * <tr><td>Ö</td><td>OE</td></tr>
     * <tr><td>Ø</td><td>OE</td></tr>
     * <tr><td>Ü</td><td>UE</td></tr>
     * <tr><td>ß</td><td>SS</td></tr>
     * </table>
     * <p/>
     * Examples:<ul>
     * <li><code>toMrz("Sedím na konári", 20)</code> yields <code>"SEDIM&lt;NA&lt;KONARI&lt;&lt;&lt;&lt;&lt;"</code></li>
     * <li><code>toMrz("Pat, Mat", 8)</code> yields <code>"PAT&lt;&lt;MAT"</code></li>
     * <li><code>toMrz("foo/bar baz", 4)</code> yields <code>"FOO&lt;"</code></li>
     * <li><code>toMrz("*$()&/\", 8)</code> yields <code>"&lt;&lt;&lt;&lt;&lt;&lt;&lt;&lt;"</code></li>
     * </ul>
     * @param string the string to convert. Passing null is the same as passing in an empty string.
     * @param length required length of the string. If given string is longer, it is truncated. If given string is shorter than given length, "&lt;" characters are appended at the end. If -1, the string is neither truncated nor enlarged.
     * @return MRZ-valid string.
     */
    public static func toMrz(_ stringIn: String?, _ length: Int) -> String {
        var string: String = stringIn ?? ""
        
        for (key, value) in MrzParser.EXPAND_CHARACTERS {
            string = string.replacingOccurrences(of: key, with: value);
        }
        string = string.replacingOccurrences(of: "’", with:"");
        string = string.replacingOccurrences(of:"'", with:"");
        string = deaccent(string).uppercased()
        if (length >= 0 && string.length > length) {
            string = string[0..<length];
        }
        var stringArray = Array(string)
        for i in 0...stringArray.count {
            if (!isValid(String(stringArray[i]))) {
                stringArray[i] = FILLER_CHAR
            }
        }
        string = String(stringArray);
        while string.length < length {
            string.append(FILLER);
        }
        return string
    }

    private static func isBlank(_ str: String?)-> Bool{
        return str == nil || (str ?? "").trimmingCharacters(in: .whitespacesAndNewlines).length == 0;
    }

    /**
     * Converts a surname and given names to a MRZ string, shortening them as per Doc 9303 Part 3 Vol 1 Section 6.7 of the MRZ specification when necessary.
     * @param surname the surname, not blank.
     * @param givenNames given names, not blank.
     * @param length required length of the string. If given string is longer, it is shortened. If given string is shorter than given length, "&lt;" characters are appended at the end.
     * @return name, properly converted to MRZ format of SURNAME&lt;&lt;GIVENNAMES&lt;..., with the exact length of given length.
     */
    public static func nameToMrz(_ pSurname: String, _ pGivenNames: String, _ length: Int) throws -> String{
        if (length <= 0) {
            throw MrzError.IllegalArgument("Parameter length: invalid value \(length): not positive");
        }
        let surname = pSurname.replacingOccurrences(of:", ", with:" ");
        let givenNames = pGivenNames.replacingOccurrences(of:", ", with:" ");
        var surnames: [String] = surname.trimmingCharacters(in: .whitespacesAndNewlines).split(usingRegex: "[ \n\t\r]+");
        var given: [String] = givenNames.trimmingCharacters(in: .whitespacesAndNewlines).split(usingRegex: "[ \n\t\r]+");
        for i in 0...surnames.count{
            surnames[i] = toMrz(surnames[i], -1);
        }
        for i in 0...given.count{
            given[i] = toMrz(given[i], -1);
        }
        // truncate
        var nameSize: Int = getNameSize(surnames, given);
        var currentlyTruncating: [String] = given;
        var currentlyTruncatingIndex: Int = given.count - 1;
        while nameSize > length {
            let ct: String = currentlyTruncating[currentlyTruncatingIndex];
            let ctsize: Int = ct.length;
            if ((nameSize - ctsize + 1) <= length) {
                currentlyTruncating[currentlyTruncatingIndex] = ct[0..<(ctsize - (nameSize - length))];
            } else {
                currentlyTruncating[currentlyTruncatingIndex] = ct[0..<1];
                currentlyTruncatingIndex = currentlyTruncatingIndex-1;
                if (currentlyTruncatingIndex < 0) {
                    if (currentlyTruncating == surnames) {
                        throw MrzError.IllegalArgument("Cannot truncate name \(surname) \(givenNames): length too small: \(length); truncated to \(toName(surnames, given))");
                    }
                    currentlyTruncating = surnames;
                    currentlyTruncatingIndex = currentlyTruncating.count - 1;
                }
            }
            nameSize = getNameSize(surnames, given);
        }
        return toMrz(toName(surnames, given), length);
    }
    /**
     * The filler character, "&lt;".
     */
    public static var FILLER: String = "<";
    public static var FILLER_CHAR: Character = Character("<");

    private static func toName(_ surnames: [String], _ given: [String] ) -> String{
        var sb: String = "";
        var first: Bool = true;
        for s in surnames {
            if (first) {
                first = false;
            } else {
                sb.append(MrzParser.FILLER);
            }
            sb.append(s);
        }
        sb.append(MrzParser.FILLER);
        for s in given {
            sb.append(MrzParser.FILLER);
            sb.append(s);
        }
        return sb
    }

    private static func getNameSize(_ surnames: [String], _ given: [String]) -> Int {
        var result: Int = 0;
        for s in surnames {
            result += s.length + 1;
        }
        for s in given {
            result += s.length + 1;
        }
        return result;
    }

    private static func deaccent(_ str: String) -> String {
        return str.folding(options: .diacriticInsensitive, locale: .current)
    }
    
    

     
    func cartesianProduct(_ arrays: [[Character]]) -> [[Character]] {
      guard let head = arrays.first else {
        return []
      }
     
      let first = Array(head)
     
      func pel(
        _ el: Character,
        _ ll: [[Character]],
        _ a: [[Character]] = []
      ) -> [[Character]] {
        switch ll.count {
        case 0:
          return a.reversed()
        case _:
          let tail = Array(ll.dropFirst())
          let head = ll.first!
     
          return pel(el, tail, el + head + a)
        }
      }
     
      return arrays.reversed()
        .reduce([first], {res, el in el.flatMap({ pel($0, res) }) })
        .map({ $0.dropLast(first.count) })
    }
}
