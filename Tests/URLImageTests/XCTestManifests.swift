import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(URLImageTests.allTests),
        testCase(RemoteImageCacheServiceTests.allTests),
        testCase(CoreDataTests.allTests)
    ]
}
#endif
