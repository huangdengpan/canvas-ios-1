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

public enum ModuleItemType: Equatable, Codable {
    case file(String)
    case discussion(String)
    case assignment(String)
    case quiz(String)
    case externalURL(URL)
    case externalTool(String, URL)
    case page(String)
    case subHeader

    public enum CodingKeys: CodingKey {
        case type
        case content_id
        case page_url
        case external_url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(APIModuleItemType.self, forKey: .type)
        switch type {
        case .file:
            let id = try container.decode(ID.self, forKey: .content_id)
            self = .file(id.value)
        case .page:
            let slug = try container.decode(String.self, forKey: .page_url)
            self = .page(slug)
        case .discussion:
            let id = try container.decode(ID.self, forKey: .content_id)
            self = .discussion(id.value)
        case .assignment:
            let id = try container.decode(ID.self, forKey: .content_id)
            self = .assignment(id.value)
        case .quiz:
            let id = try container.decode(ID.self, forKey: .content_id)
            self = .quiz(id.value)
        case .subHeader:
            self = .subHeader
        case .externalURL:
            let url = try container.decode(URL.self, forKey: .external_url)
            self = .externalURL(url)
        case .externalTool:
            let id = try container.decode(ID.self, forKey: .content_id)
            let url = try container.decode(URL.self, forKey: .external_url)
            self = .externalTool(id.value, url)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .file(let id):
            try container.encode(id, forKey: .content_id)
            try container.encode(APIModuleItemType.file, forKey: .type)
        case .page(let slug):
            try container.encode(slug, forKey: .page_url)
            try container.encode(APIModuleItemType.page, forKey: .type)
        case .discussion(let id):
            try container.encode(id, forKey: .content_id)
            try container.encode(APIModuleItemType.discussion, forKey: .type)
        case .assignment(let id):
            try container.encode(id, forKey: .content_id)
            try container.encode(APIModuleItemType.assignment, forKey: .type)
        case .quiz(let id):
            try container.encode(id, forKey: .content_id)
            try container.encode(APIModuleItemType.quiz, forKey: .type)
        case .subHeader:
            try container.encode(APIModuleItemType.subHeader, forKey: .type)
        case .externalURL(let url):
            try container.encode(url, forKey: .external_url)
            try container.encode(APIModuleItemType.externalURL, forKey: .type)
        case .externalTool(let id, let url):
            try container.encode(id, forKey: .content_id)
            try container.encode(url, forKey: .external_url)
            try container.encode(APIModuleItemType.externalTool, forKey: .type)
        }
    }

    public static func == (lhs: ModuleItemType, rhs: ModuleItemType) -> Bool {
        switch (lhs, rhs) {
        case let (.file(lhs), .file(rhs)):
            return lhs == rhs
        case let (.discussion(lhs), .discussion(rhs)):
            return lhs == rhs
        case let (.assignment(lhs), .assignment(rhs)):
            return lhs == rhs
        case let (.quiz(lhs), .quiz(rhs)):
            return lhs == rhs
        case let (.externalURL(lhs), .externalURL(rhs)):
            return lhs == rhs
        case let (.externalTool(lhsID, lhsURL), .externalTool(rhsID, rhsURL)):
            return lhsID == rhsID && lhsURL == rhsURL
        case let (.page(lhs), .page(rhs)):
            return lhs == rhs
        case (.subHeader, .subHeader):
            return true
        default:
            return false
        }
    }

    public var icon: UIImage? {
        switch self {
        case .subHeader:
            return nil
        case .file:
            return .icon(.folder)
        case .page:
            return .icon(.document)
        case .discussion:
            return .icon(.discussion)
        case .assignment:
            return .icon(.assignment)
        case .quiz:
            return .icon(.quiz)
        case .externalURL:
            return .icon(.link)
        case .externalTool:
            return .icon(.lti)
        }
    }
}
