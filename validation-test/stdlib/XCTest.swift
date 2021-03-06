// RUN: %target-run-stdlib-swift
// REQUIRES: executable_test

// REQUIRES: objc_interop

// REQUIRES: OS=macosx

// watchOS 2.0 does not have an XCTest module.
// XFAIL: OS=watchos

import StdlibUnittest


import XCTest

var XCTestTestSuite = TestSuite("XCTest")

// NOTE: When instantiating test cases for a particular test method using the
//       XCTestCase(selector:) initializer, those test methods must be marked
//       as dynamic. Objective-C XCTest uses runtime introspection to
//       instantiate an NSInvocation with the given selector.


func execute(observers: [XCTestObservation] = [], _ run: () -> Void) {
  for observer in observers {
    XCTestObservationCenter.shared().addTestObserver(observer)
  }

  run()

  for observer in observers {
    XCTestObservationCenter.shared().removeTestObserver(observer)
  }
}

class FailureDescriptionObserver: NSObject, XCTestObservation {
  var failureDescription: String?

  func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: UInt) {
    failureDescription = description
  }
}

XCTestTestSuite.test("exceptions") {
  class ExceptionTestCase: XCTestCase {
    dynamic func test_raises() {
      NSException(name: "XCTestTestSuiteException", reason: nil, userInfo: nil).raise()
    }
  }

  let testCase = ExceptionTestCase(selector: #selector(ExceptionTestCase.test_raises))
  execute(testCase.run)
  let testRun = testCase.testRun!

  expectEqual(1, testRun.testCaseCount)
  expectEqual(1, testRun.executionCount)
  expectEqual(0, testRun.failureCount)
  expectEqual(1, testRun.unexpectedExceptionCount)
  expectEqual(1, testRun.totalFailureCount)
  expectFalse(testRun.hasSucceeded)
}

XCTestTestSuite.test("XCTAssertEqual/T") {
  class AssertEqualTestCase: XCTestCase {
    dynamic func test_whenEqual_passes() {
      XCTAssertEqual(1, 1)
    }

    dynamic func test_whenNotEqual_fails() {
      XCTAssertEqual(1, 2)
    }
  }

  let passingTestCase = AssertEqualTestCase(selector: #selector(AssertEqualTestCase.test_whenEqual_passes))
  execute(passingTestCase.run)
  let passingTestRun = passingTestCase.testRun!
  expectTrue(passingTestRun.hasSucceeded)

  let failingTestCase = AssertEqualTestCase(selector: #selector(AssertEqualTestCase.test_whenNotEqual_fails))
  let observer = FailureDescriptionObserver()
  execute(observers: [observer], failingTestCase.run)
  let failingTestRun = failingTestCase.testRun!
  expectEqual(1, failingTestRun.failureCount)
  expectEqual(0, failingTestRun.unexpectedExceptionCount)
  expectEqual(observer.failureDescription, "XCTAssertEqual failed: (\"1\") is not equal to (\"2\") - ")
}

XCTestTestSuite.test("XCTAssertEqual/Optional<T>") {
  class AssertEqualOptionalTestCase: XCTestCase {
    dynamic func test_whenOptionalsAreEqual_passes() {
      XCTAssertEqual(Optional(1),Optional(1))
    }

    dynamic func test_whenOptionalsAreNotEqual_fails() {
      XCTAssertEqual(Optional(1),Optional(2))
    }
  }

  let passingTestCase = AssertEqualOptionalTestCase(selector: #selector(AssertEqualOptionalTestCase.test_whenOptionalsAreEqual_passes))
  execute(passingTestCase.run)
  let passingTestRun = passingTestCase.testRun!
  expectEqual(1, passingTestRun.testCaseCount)
  expectEqual(1, passingTestRun.executionCount)
  expectEqual(0, passingTestRun.failureCount)
  expectEqual(0, passingTestRun.unexpectedExceptionCount)
  expectEqual(0, passingTestRun.totalFailureCount)
  expectTrue(passingTestRun.hasSucceeded)

  let failingTestCase = AssertEqualOptionalTestCase(selector: #selector(AssertEqualOptionalTestCase.test_whenOptionalsAreNotEqual_fails))
  let observer = FailureDescriptionObserver()
  execute(observers: [observer], failingTestCase.run)
  let failingTestRun = failingTestCase.testRun!
  expectEqual(1, failingTestRun.testCaseCount)
  expectEqual(1, failingTestRun.executionCount)
  expectEqual(1, failingTestRun.failureCount)
  expectEqual(0, failingTestRun.unexpectedExceptionCount)
  expectEqual(1, failingTestRun.totalFailureCount)
  expectFalse(failingTestRun.hasSucceeded)
  expectEqual(observer.failureDescription, "XCTAssertEqual failed: (\"Optional(1)\") is not equal to (\"Optional(2)\") - ")
}

XCTestTestSuite.test("XCTAssertEqual/Array<T>") {
  class AssertEqualArrayTestCase: XCTestCase {
    dynamic func test_whenArraysAreEqual_passes() {
      XCTAssertEqual(["foo", "bar", "baz"],
                     ["foo", "bar", "baz"])
    }

    dynamic func test_whenArraysAreNotEqual_fails() {
      XCTAssertEqual(["foo", "baz", "bar"],
                     ["foo", "bar", "baz"])
    }
  }

  let passingTestCase = AssertEqualArrayTestCase(selector: #selector(AssertEqualArrayTestCase.test_whenArraysAreEqual_passes))
  execute(passingTestCase.run)
  let passingTestRun = passingTestCase.testRun!
  expectEqual(1, passingTestRun.testCaseCount)
  expectEqual(1, passingTestRun.executionCount)
  expectEqual(0, passingTestRun.failureCount)
  expectEqual(0, passingTestRun.unexpectedExceptionCount)
  expectEqual(0, passingTestRun.totalFailureCount)
  expectTrue(passingTestRun.hasSucceeded)

  let failingTestCase = AssertEqualArrayTestCase(selector: #selector(AssertEqualArrayTestCase.test_whenArraysAreNotEqual_fails))
  execute(failingTestCase.run)
  let failingTestRun = failingTestCase.testRun!
  expectEqual(1, failingTestRun.testCaseCount)
  expectEqual(1, failingTestRun.executionCount)
  expectEqual(1, failingTestRun.failureCount)
  expectEqual(0, failingTestRun.unexpectedExceptionCount)
  expectEqual(1, failingTestRun.totalFailureCount)
  expectFalse(failingTestRun.hasSucceeded)
}

XCTestTestSuite.test("XCTAssertEqual/Dictionary<T, U>") {
  class AssertEqualDictionaryTestCase: XCTestCase {
    dynamic func test_whenDictionariesAreEqual_passes() {
      XCTAssertEqual(["foo": "bar", "baz": "flim"],
                     ["baz": "flim", "foo": "bar"])
    }

    dynamic func test_whenDictionariesAreNotEqual_fails() {
      XCTAssertEqual(["foo": ["bar": "baz"]],
                     ["foo": ["bar": "flim"]])
    }
  }

  let passingTestCase = AssertEqualDictionaryTestCase(selector: #selector(AssertEqualDictionaryTestCase.test_whenDictionariesAreEqual_passes))
  execute(passingTestCase.run)
  let passingTestRun = passingTestCase.testRun!
  expectEqual(1, passingTestRun.testCaseCount)
  expectEqual(1, passingTestRun.executionCount)
  expectEqual(0, passingTestRun.failureCount)
  expectEqual(0, passingTestRun.unexpectedExceptionCount)
  expectEqual(0, passingTestRun.totalFailureCount)
  expectTrue(passingTestRun.hasSucceeded)

  let failingTestCase = AssertEqualDictionaryTestCase(selector: #selector(AssertEqualDictionaryTestCase.test_whenDictionariesAreNotEqual_fails))
  execute(failingTestCase.run)
  let failingTestRun = failingTestCase.testRun!
  expectEqual(1, failingTestRun.testCaseCount)
  expectEqual(1, failingTestRun.executionCount)
  expectEqual(1, failingTestRun.failureCount)
  expectEqual(0, failingTestRun.unexpectedExceptionCount)
  expectEqual(1, failingTestRun.totalFailureCount)
  expectFalse(failingTestRun.hasSucceeded)
}

XCTestTestSuite.test("XCTAssertThrowsError") {
    class ErrorTestCase: XCTestCase {
        var doThrow = true
        var errorCode = 42
        
        dynamic func throwSomething() throws {
            if doThrow {
                throw NSError(domain: "MyDomain", code: errorCode, userInfo: nil)
            }
        }

        dynamic func test_throws() {
            XCTAssertThrowsError(try throwSomething()) {
                error in
                let nserror = error as NSError
                XCTAssertEqual(nserror.domain, "MyDomain")
                XCTAssertEqual(nserror.code, 42)
            }
        }
    }
    
    // Try success case
    do {
        let testCase = ErrorTestCase(selector: #selector(ErrorTestCase.test_throws))
        execute(testCase.run)
        let testRun = testCase.testRun!
        
        expectEqual(1, testRun.testCaseCount)
        expectEqual(1, testRun.executionCount)
        expectEqual(0, testRun.failureCount)
        expectEqual(0, testRun.unexpectedExceptionCount)
        expectEqual(0, testRun.totalFailureCount)
        expectTrue(testRun.hasSucceeded)
    }

    // Now try when it does not throw
    do {
        let testCase = ErrorTestCase(selector: #selector(ErrorTestCase.test_throws))
        testCase.doThrow = false
        execute(testCase.run)
        let testRun = testCase.testRun!
        
        expectEqual(1, testRun.testCaseCount)
        expectEqual(1, testRun.executionCount)
        expectEqual(1, testRun.failureCount)
        expectEqual(0, testRun.unexpectedExceptionCount)
        expectEqual(1, testRun.totalFailureCount)
        expectFalse(testRun.hasSucceeded)
    }

    
    // Now try when it throws the wrong thing
    do {
        let testCase = ErrorTestCase(selector: #selector(ErrorTestCase.test_throws))
        testCase.errorCode = 23
        execute(testCase.run)
        let testRun = testCase.testRun!
        
        expectEqual(1, testRun.testCaseCount)
        expectEqual(1, testRun.executionCount)
        expectEqual(1, testRun.failureCount)
        expectEqual(0, testRun.unexpectedExceptionCount)
        expectEqual(1, testRun.totalFailureCount)
        expectFalse(testRun.hasSucceeded)
    }

}

XCTestTestSuite.test("XCTAsserts with throwing expressions") {
    class ErrorTestCase: XCTestCase {
        var doThrow = true
        var errorCode = 42
        
        dynamic func throwSomething() throws -> String {
            if doThrow {
                throw NSError(domain: "MyDomain", code: errorCode, userInfo: nil)
            }
            return "Hello"
        }
        
        dynamic func test_withThrowing() {
            XCTAssertEqual(try throwSomething(), "Hello")
        }
    }
    
    // Try success case
    do {
        let testCase = ErrorTestCase(selector: #selector(ErrorTestCase.test_withThrowing))
        testCase.doThrow = false
        execute(testCase.run)
        let testRun = testCase.testRun!
        
        expectEqual(1, testRun.testCaseCount)
        expectEqual(1, testRun.executionCount)
        expectEqual(0, testRun.failureCount)
        expectEqual(0, testRun.unexpectedExceptionCount)
        expectEqual(0, testRun.totalFailureCount)
        expectTrue(testRun.hasSucceeded)
    }
    
    // Now try when the expression throws
    do {
        let testCase = ErrorTestCase(selector: #selector(ErrorTestCase.test_withThrowing))
        execute(testCase.run)
        let testRun = testCase.testRun!
        
        expectEqual(1, testRun.testCaseCount)
        expectEqual(1, testRun.executionCount)
        expectEqual(0, testRun.failureCount)
        expectEqual(1, testRun.unexpectedExceptionCount)
        expectEqual(1, testRun.totalFailureCount)
        expectFalse(testRun.hasSucceeded)
    }
    
}

XCTestTestSuite.test("Test methods that wind up throwing") {
    class ErrorTestCase: XCTestCase {
        var doThrow = true
        var errorCode = 42
        
        dynamic func throwSomething() throws {
            if doThrow {
                throw NSError(domain: "MyDomain", code: errorCode, userInfo: nil)
            }
        }
        
        dynamic func test_withThrowing() throws {
            try throwSomething()
        }
    }
    
    // Try success case
    do {
        let testCase = ErrorTestCase(selector: #selector(ErrorTestCase.test_withThrowing))
        testCase.doThrow = false
        execute(testCase.run)
        let testRun = testCase.testRun!
        
        expectEqual(1, testRun.testCaseCount)
        expectEqual(1, testRun.executionCount)
        expectEqual(0, testRun.failureCount)
        expectEqual(0, testRun.unexpectedExceptionCount)
        expectEqual(0, testRun.totalFailureCount)
        expectTrue(testRun.hasSucceeded)
    }
    
    // Now try when the expression throws
    do {
        let testCase = ErrorTestCase(selector: #selector(ErrorTestCase.test_withThrowing))
        execute(testCase.run)
        let testRun = testCase.testRun!
        
        expectEqual(1, testRun.testCaseCount)
        expectEqual(1, testRun.executionCount)
        expectEqual(0, testRun.failureCount)
        expectEqual(1, testRun.unexpectedExceptionCount)
        expectEqual(1, testRun.totalFailureCount)
        expectFalse(testRun.hasSucceeded)
    }
    
}

runAllTests()

