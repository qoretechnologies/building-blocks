# -*- mode: qore; indent-tabs-mode: nil -*-
# Qore ExcelReadDataProvider class definition

/*  ExcelReadDataProvider.qc Copyright 2021 - 2022 Qore Technologies, s.r.o.

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
*/

#! the ExcelDataProvider namespace. All classes used in the ExcelDataProvider module should be inside this namespace
public namespace ExcelDataProvider {
#! Designates a cell location in a worksheet
public hashdecl CellLocationInfo {
    #! The column name
    string column;
    #! The row number
    int row;
}

#! Designates a range of cells
public hashdecl CellRangeInfo {
    #! The start cell
    hash<CellLocationInfo> start;
    #! The end cell
    hash<CellLocationInfo> end;
}

#! Provides a data provider for reading EXCEL files
public class ExcelReadDataProvider inherits DataProvider::AbstractDataProvider {
    public {
        #! Provider info
        const ProviderInfo = <DataProviderInfo>{
            "type": "ExcelReadDataProvider",
            "supports_children": True,
            "constructor_options": ConstructorOptions,
        };

        #! Constructor options
        const ConstructorOptions = {
            "data_cells": <DataProviderOptionInfo>{
                "type": AbstractDataProviderType::get(StringType),
                "desc": "the range of cells for data to process",
            },
            "header_cells": <DataProviderOptionInfo>{
                "type": AbstractDataProviderType::get(SoftStringType),
                "desc": "the range of cells for headers or a row number",
            },
            "header_names": <DataProviderOptionInfo>{
                "type": AbstractDataProviderType::get(SoftBoolType),
                "desc": "if `true` then the object will parse the header names from the first header row, in this "
                    "case if `header_cells` is not set explicitly, it will be assumed to be `1`",
            },
            "headers": <DataProviderOptionInfo>{
                "type": AbstractDataProviderType::get(new Type("softlist<string>")),
                "desc": "list of header / column names for the data iterated; if this is present, then "
                    "`header_names` must be `false`",
            },
            "path": <DataProviderOptionInfo>{
                "type": AbstractDataProviderType::get(StringType),
                "desc": "the path to the Excel data; mutually exclusive with \"stream\"",
            },
            "stream": <DataProviderOptionInfo>{
                "type": AbstractDataProviderType::get(new Type("InputStream")),
                "desc": "an input stream for Excel data; mutually exclusive with \"path\"",
            },
            "timezone": <DataProviderOptionInfo>{
                "type": AbstractDataProviderType::get(StringType),
                "desc": "the timezone region to use when parsing dates (ex: `Europe/Prague`)",
            },
            "tolwr": <DataProviderOptionInfo>{
                "type": AbstractDataProviderType::get(SoftBoolType),
                "desc": "if `true` (default `false`), all automatically-detected header names will be converted to "
                    "lower case letters",
            },
        };

        #! Excel iteration option list
        const ExcelIterationOptionList = keys (ConstructorOptions - ("path", "stream"));
    }

    private {
        #! The inpjut stream for the Excel data
        InputStream i;

        #! The path to the Excel file
        string path;

        #! The name of the object
        string name;

        #! Excel iteration options
        *hash<auto> opts;
    }

    #! Creates the ExcelReadDataProvider with the input data path and optionally an option hash
    /** @param path the input file to iterate
        @param opts a hash of optional options

        @throw EXCEL-READ-OPTION-ERROR invalid or unknown option; invalid data type for option; \c "header_names"
        is @ref True "True" and \c "headers" is also present; unknown field type
        @throw EXCEL-INVALID-LOCATION invalid excel location or range string
    */
    constructor(string path, *hash<auto> opts) {
        name = path;
        self.path = path;
        self.opts = processCellOptions(checkOptions("EXCEL-READ-OPTION-ERROR", ConstructorOptions, opts));
    }

    #! Creates the ExcelReadDataProvider with the input data stream and optionally an option hash
    /** @param stream the input stream to iterate
        @param opts a hash of optional options

        @throw EXCEL-READ-OPTION-ERROR invalid or unknown option; invalid data type for option; \c "header_names"
        is @ref True "True" and \c "headers" is also present; unknown field type
        @throw EXCEL-INVALID-LOCATION invalid excel location or range string
    */
    constructor(InputStream stream, *hash<auto> opts) {
        i = stream;
        self.opts = processCellOptions(checkOptions("EXCEL-READ-OPTION-ERROR", ConstructorOptions, opts));
        name = sprintf("stream=%s", stream.uniqueHash());
    }

    #! Creates the object from constructor options
    /**
        @throw EXCEL-READ-OPTION-ERROR invalid or unknown option; invalid data type for option; \c "header_names"
        is @ref True "True" and \c "headers" is also present; unknown field type
        @throw EXCEL-INVALID-LOCATION invalid excel location or range string
    */
    constructor(*hash<auto> options) {
        *hash<auto> copts = processCellOptions(checkOptions("EXCEL-READ-OPTION-ERROR", ConstructorOptions, options));
        if (copts.path) {
            if (copts.stream) {
                error("EXCEL-READ-OPTION-ERROR", "cannot provide both \"stream\" and \"path\" options; use either one or "
                    "the other");
            }
            name = path = copts.path;
        } else if (copts.stream) {
            i = copts.stream;
            name = sprintf("stream=%s", i.uniqueHash());
        }
        self.opts = copts - ("stream", "path");
        if (!i && !path) {
            # create a dummy interator with no input
            i = new StringInputStream("");
        }
    }

    #! Returns the object name
    string getName() {
        return name;
    }

    #! Process cell options
    static *hash<auto> processCellOptions(*hash<auto> opts) {
        if (opts.header_cells) {
            opts.header_cells = ExcelReadDataProvider::parseRange(opts.header_cells);
        }
        if (opts.data_cells) {
            opts.data_cells = ExcelReadDataProvider::parseRange(opts.data_cells);
            if (opts.header_cells) {
                if (opts.header_cells.start.column > opts.data_cells.start.column) {
                    throw "EXCEL-INVALID-LOCATION", sprintf("start column for header cells (%y) is after the start column for "
                        "data cells (%y)", opts.header_cells.start, opts.data_cells.start);
                }
                if (opts.header_cells.start.row > opts.data_cells.start.row) {
                    throw "EXCEL-INVALID-LOCATION", sprintf("start row for header cells (%y) is after the start row for data "
                        "cells  (%y)", opts.header_cells.start, opts.data_cells.start);
                }
            }
        }
        return opts;
    }

    #! Parses a string that designates a range of cells (ex: \c "a1:e10")
    /** @throw EXCEL-INVALID-LOCATION invalid excel location or range string
    */
    static hash<CellRangeInfo> parseRange(string range) {
        (*string start, *string end) = (range =~ x/^((?:[a-z]+)?[0-9]+)(?::((?:[a-z]+)?[0-9]+))?$/i);
        if (!start) {
            throw "EXCEL-INVALID-LOCATION", sprintf("range %y does not have the format [a-z]+[0-9]+:[a-z]+[0-9]+", range);
        }
        hash<CellRangeInfo> rv = <CellRangeInfo>{
            "start": ExcelReadDataProvider::parseCellLocation(start),
        };
        if (end) {
            rv.end = ExcelReadDataProvider::parseCellLocation(end);
            if (rv.start.column > rv.end.column) {
                throw "EXCEL-INVALID-LOCATION", sprintf("start column (%y) is after the end column (%y)", start, end);
            }
            if (rv.start.row > rv.end.row) {
                throw "EXCEL-INVALID-LOCATION", sprintf("start row (%y) is after the end row (%y)", start, end);
            }
        } else {
            rv.end = <CellLocationInfo>{
                "column": "-",
                "row": -1,
            };
        }
        return rv;
    }

    #! Parses a string that designates a cell location (ex: \c "a1")
    /** @throw INVALID-LOCATION invalid excel location or range string
    */
    static hash<CellLocationInfo> parseCellLocation(string location) {
        *list<*string> row_values = (location =~ x/^(?:[a-z]+)?([0-9]+)$/i);
        hash<CellLocationInfo> rv = <CellLocationInfo>{
            "column": (location =~ x/^([a-z]+)[0-9]+/i)[0] ?? "-",
            "row": (row_values[1] ?? row_values[0] ?? -1).toInt(),
        };
        if (rv.row < 1) {
            throw "EXCEL-INVALID-LOCATION", sprintf("row %y is invalid, rows numbers must be >= 1", rv.row);
        }
        return rv;
    }

    #! Returns a list of child data provider names, if any
    /** @return a list of child data provider names, if any
    */
    private *list<string> getChildProviderNamesImpl() {
        # if we are dealing with a FileInputStream, then we have to reset it after reading the stream
        # otherwise we have to read the entire stream into binary object and reset it with that
        binary b;
        if (!path) {
            b = i.read(999999999) ?? binary();
            i = new BinaryInputStream(b);
        }
        on_exit if (!path) {
            i = new BinaryInputStream(b);
        }
        return ExcelIterator::getWorksheets(i ?? path);
    }

    #! Returns the given child provider or @ref nothing if the given child is unknown
    /** @return the given child provider or @ref nothing if the given child is unknown
    */
    private *AbstractDataProvider getChildProviderImpl(string child_name) {
        *hash<string, bool> sheets = map {$1: True}, getChildProviderNamesImpl();
        if (sheets{child_name}) {
            return new ExcelWorksheetReadDataProvider(i ?? path, name, child_name, opts);
        }
    }

    #! Returns data provider static info
    private hash<DataProviderInfo> getStaticInfoImpl() {
        return ProviderInfo;
    }
}
} # ExcelDataProvider namespace
