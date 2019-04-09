//
// Copyright (C) 2019-present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
@testable import Core

extension CalendarEvent: Fixture {
    public static var template: Template {
        return [
            "id": "1",
            "contextRaw": "course_1",
            "title": "calendar event #1",
            "type": "event",
            "startAt": Date().addDays(-365),
            "endAt": Date().addDays(365),
            "htmlUrl": URL(string: "https://narmstrong.instructure.com/calendar?event_id=10&include_contexts=course_1")!,
        ]
    }
}