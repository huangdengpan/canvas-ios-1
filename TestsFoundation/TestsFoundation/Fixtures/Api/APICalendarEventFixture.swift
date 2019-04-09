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

extension APICalendarEvent: Fixture {
    public static var template: Template {
        return [
            "id": "1",
            "title": "calendar event #1",
            "type": "event",
            "start_at": "2018-05-18T06:00:00Z",
            "end_at": "2018-05-18T06:00:00Z",
            "html_url": "https://narmstrong.instructure.com/calendar?event_id=10&include_contexts=course_1",
            "context_code": "course_1",
        ]
    }
}
