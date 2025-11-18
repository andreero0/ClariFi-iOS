#!/bin/bash

# Script to convert XCTest files to Swift Testing format

TEST_DIR="/Users/mayenikhalo/Public/From aEroPartition/Dev/ClariFi iOS/ClariFi iOSTests"

echo "Converting test files to Swift Testing format..."

# Function to convert a single file
convert_file() {
    local file="$1"
    echo "Converting $file..."
    
    # Replace imports
    sed -i '' 's/import XCTest/import Testing/g' "$file"
    
    # Replace class with struct
    sed -i '' 's/class \([A-Za-z]*Tests\): XCTestCase {/struct \1 {/g' "$file"
    
    # Replace setUp with init
    sed -i '' 's/override func setUp() {/init() throws {/g' "$file"
    sed -i '' 's/super\.setUp()//g' "$file"
    
    # Remove tearDown methods
    sed -i '' '/override func tearDown() {/,/}/d' "$file"
    
    # Add @Test to test functions
    sed -i '' 's/func test\([A-Za-z]*\)() throws {/@Test func \1() throws {/g' "$file"
    sed -i '' 's/func test\([A-Za-z]*\)() {/@Test func \1() {/g' "$file"
    
    # Convert XCTAssert statements
    sed -i '' 's/XCTAssertEqual(\([^,]*\), \([^)]*\))/#expect(\1 == \2)/g' "$file"
    sed -i '' 's/XCTAssertNotEqual(\([^,]*\), \([^)]*\))/#expect(\1 != \2)/g' "$file"
    sed -i '' 's/XCTAssertTrue(\([^)]*\))/#expect(\1 == true)/g' "$file"
    sed -i '' 's/XCTAssertFalse(\([^)]*\))/#expect(\1 == false)/g' "$file"
    sed -i '' 's/XCTAssertNil(\([^)]*\))/#expect(\1 == nil)/g' "$file"
    sed -i '' 's/XCTAssertNotNil(\([^)]*\))/#expect(\1 != nil)/g' "$file"
    sed -i '' 's/XCTAssertGreaterThan(\([^,]*\), \([^)]*\))/#expect(\1 > \2)/g' "$file"
    sed -i '' 's/XCTAssertGreaterThanOrEqual(\([^,]*\), \([^)]*\))/#expect(\1 >= \2)/g' "$file"
    sed -i '' 's/XCTAssertLessThan(\([^,]*\), \([^)]*\))/#expect(\1 < \2)/g' "$file"
    sed -i '' 's/XCTAssertLessThanOrEqual(\([^,]*\), \([^)]*\))/#expect(\1 <= \2)/g' "$file"
    
    # Convert XCTUnwrap to #require
    sed -i '' 's/try XCTUnwrap(\([^)]*\))/try #require(\1)/g' "$file"
    
    # Convert XCTFail to Issue.record
    sed -i '' 's/XCTFail(\([^)]*\))/Issue.record(\1)/g' "$file"
    
    echo "Converted $file"
}

# Convert all Swift test files
for file in "$TEST_DIR"/*.swift; do
    if [ -f "$file" ]; then
        convert_file "$file"
    fi
done

echo "Conversion complete!"
