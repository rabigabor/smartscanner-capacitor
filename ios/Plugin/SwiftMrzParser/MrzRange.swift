//
//  File.swift
//  
//
//  Created by rabigabor on 2021. 12. 05..
//

import Foundation

public class MrzRange: CustomStringConvertible{
    
    /**
     * 0-based index of first character in the range.
     */
    public final var column: Int;
    /**
     * 0-based index of a character after last character in the range.
     */
    public final var columnTo: Int;
    /**
     * 0-based row.
     */
    public final var row: Int;
    
        
    

    /**
     * Creates new MRZ range object.
     * @param column 0-based index of first character in the range.
     * @param columnTo 0-based index of a character after last character in the range.
     * @param row 0-based row.
     */
    init(_ column: Int, _ columnTo: Int, _ row: Int) throws{
        if (column > columnTo) {
            throw MrzError.IllegalArgument("Parameter column: invalid value \(column): must be less than \(columnTo)");
        }
        self.column = column;
        self.columnTo = columnTo;
        self.row = row;
    }

    public func toString() -> String {
        return "\(column)-\(columnTo),\(row)";
    }
    public var description: String {
        return "\(column)-\(columnTo),\(row)";
    }

    /**
     * Returns length of this range.
     * @return number of characters, which this range covers.
     */
    public func length() -> Int {
        return columnTo - column;
    }
}
