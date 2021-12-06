//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MrzFormat: Equatable{
    
    
    public final var rows: Int;
    public final var columns: Int;
    
    
    
    init(_ rows: Int, _ columns: Int) {
        self.rows = rows;
        self.columns = columns;
    }

    public static func == (lhs: MrzFormat, rhs: MrzFormat) -> Bool {
        return lhs.rows == rhs.rows && lhs.columns == rhs.columns && type(of:lhs) == type(of:rhs);
    }
    /**
     * Checks if this format is able to parse given serialized MRZ record.
     * @param mrzRows MRZ record, separated into rows.
     * @return true if given MRZ record is of this type, false otherwise.
     */
    public func isFormatOf(_ mrzRows: [String]) -> Bool {
        return self.rows == mrzRows.count && self.columns == mrzRows[0].length;
    }

    /**
     * Detects given MRZ format.
     * @param mrz the MRZ string.
     * @return the format, never null.
     */
    public static func get(_ mrz: String) throws -> MrzFormat {
        let dummyRow: Int = 44;
        var rows: [String] = mrz.components(separatedBy: "\n");
        let cols: Int = rows[0].count;
        print("SmartScanner", "mrz: " + mrz);
        print("SmartScanner", "rows: " + rows.joined(separator: ", "));
        var mrzBuilder = String(mrz);
        for i in 0..<rows.count{
            if (rows[i].count != cols) {
                if (rows[i].count != dummyRow) {
                    mrzBuilder.append("<");
                }
            }
        }
        let mrzNew = String(mrzBuilder);
        rows = mrzNew.components(separatedBy: "\n");
        
        let types: [MrzFormat] = [MRTD_TD1(), MRTD_TD2(), PASSPORT(), MRV_VISA_A(), MRV_VISA_B()]
        
        for f in types {
            if (f.isFormatOf(rows)) {
                return f;
            }
        }
        throw MrzError.ParseException("Unknown format / unsupported number of cols/rows: \(cols)/\(rows.count)", mrz, try MrzRange(0, 0, 0), nil);
    }

    /**
     * Creates new record instance with this type.
     * @return never null record instance.
     */
    public func newRecord() -> MrzRecord {
        fatalError("NotImplementedError")
    }
}


/**
 * MRV type-B format: A two lines long, 36 characters per line format.
 * Need to occur before the {@link #MRTD_TD2} enum constant because of the same values for row/column.
 * See below for the "if" test.
 */
public class MRV_VISA_B: MrzFormat {
    
    init(){
        super.init(2, 36)
    }
    
    public override func newRecord() -> MrzRecord {
        return MrvB(self)
    }
    
   public override func isFormatOf(_ mrzRows: [String]) -> Bool {
        if (!super.isFormatOf(mrzRows)) {
            return false;
        }
        return mrzRows[0].starts(with:"V");
    }
};
/**
 * MRTD td2 format: A two line long, 36 characters per line format.
 */
public class MRTD_TD2: MrzFormat{
    init(){
        super.init(2, 36);
    }
    public override func newRecord() -> MrzRecord {
        return MrtdTd2(self)
    }
}
/**
 * MRV type-A format: A two lines long, 44 characters per line format
 * Need to occur before {@link #PASSPORT} constant because of the same values for row/column.
 * See below for the "if" test.
 */
public class MRV_VISA_A: MrzFormat{
    
    init(){
        super.init(2, 44)
    }
    public override func newRecord() -> MrzRecord {
        return MrvA(self)
    }
    
   public override func isFormatOf(_ mrzRows: [String]) -> Bool {
        if (!super.isFormatOf(mrzRows)) {
            return false;
        }
        return mrzRows[0].starts(with:"V");
    }
};
/**
 * MRP Passport format: A two line long, 44 characters per line format.
 */
public class PASSPORT: MrzFormat{
    init(){
        super.init(2, 44);
    }
    public override func newRecord() -> MrzRecord {
        return MRP(self)
    }
}

/**
 * MRTD td1 format: A three line long, 30 characters per line format.
 */
public class MRTD_TD1: MrzFormat{
    init(){
        super.init(3, 30);
    }
    public override func newRecord() -> MrzRecord {
        return MrtdTd1(self)
    }
}
