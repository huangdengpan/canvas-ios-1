//
// Copyright (C) 2018-present Instructure, Inc.
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

import UIKit

extension UITabBar {
    /// Styles the `UITabBar` to use some elements of the organizations branding colors
    public func useGlobalNavStyle(brand: Brand = Brand.shared) {
        let hasEnoughContrast = brand.navBackground.contrast(against: UIColor.named(.backgroundLightest)) >= 3
        let activeColor = hasEnoughContrast ? brand.navBackground : brand.navTextColor
        tintColor = activeColor.ensureContrast(against: .named(.backgroundLightest))

        barStyle = .default
        barTintColor = .named(.backgroundLightest)
        unselectedItemTintColor = .named(.textDark)

        // There are weird RN view sizing issues with opaque tabBars, so emulate with backgroundColor.
        isTranslucent = true
        backgroundColor = .named(.backgroundLightest)

        for item in items ?? [] {
            item.badgeColor = .named(.crimson)
            item.setBadgeTextAttributes([.foregroundColor: UIColor.named(.textLightest)], for: .normal)
        }
    }
}
