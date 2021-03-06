//
// Copyright (C) 2018-present Instructure, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
@testable import Core
@testable import Student
import TestsFoundation

class SubmissionCommentsView: SubmissionCommentsViewProtocol {
    var didReload = false
    func reload() {
        didReload = true
    }

    var error: Error?
    var expectError: XCTestExpectation?
    func showError(_ error: Error) {
        self.error = error
        expectError?.fulfill()
    }
}

class SubmissionCommentsPresenterTests: PersistenceTestCase {
    var presenter: SubmissionCommentsPresenter!
    var view: SubmissionCommentsView!

    override func setUp() {
        super.setUp()
        view = SubmissionCommentsView()
        presenter = SubmissionCommentsPresenter(env: env, view: view, context: ContextModel(.course, id: "1"), assignmentID: "1", userID: "1", submissionID: "1")
    }

    func testViewIsReady() {
        presenter.viewIsReady()
        XCTAssertTrue(view.didReload)
    }

    func testUpdate() {
        presenter.update()
        XCTAssertTrue(view.didReload)
    }

    func testAddComment() {
        view.expectError = expectation(description: "error")
        presenter.addComment(text: "hello")
        wait(for: [view.expectError!], timeout: 5)
        XCTAssertNotNil(view.error)
    }

    func testAddMediaComment() {
        view.expectError = expectation(description: "error")
        presenter.addMediaComment(type: .audio, url: URL(string: "/")!)
        wait(for: [view.expectError!], timeout: 5)
        XCTAssertNotNil(view.error)
    }
}
