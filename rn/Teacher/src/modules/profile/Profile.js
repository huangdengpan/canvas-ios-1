//
// Copyright (C) 2017-present Instructure, Inc.
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

/* @flow */

import React, { Component } from 'react'
import {
  View,
  NativeModules,
  StyleSheet,
  ScrollView,
  ActionSheetIOS,
  Linking,
  TouchableWithoutFeedback,
  SafeAreaView,
  AsyncStorage,
  LayoutAnimation,
} from 'react-native'
import i18n from 'format-message'
import { purgeUserStoreData } from '@redux/middleware/persist'
import { Text, Paragraph, Heavy } from '@common/text'
import Avatar from '@common/components/Avatar'
import Screen from '@routing/Screen'
import color from '@common/colors'
import device from 'react-native-device-info'
import Row from '@common/components/rows/Row'
import RowWithSwitch from '@common/components/rows/RowWithSwitch'
import RowSeparator from '@common/components/rows/RowSeparator'
import { isStudent, isParent } from '@modules/app'
import canvas, { getSession, httpCache } from '@canvas-api'
import { connect } from 'react-redux'
import Actions from '@modules/userInfo/actions'
import StatusBar from '@common/components/StatusBar'
import * as LTITools from '@common/LTITools'
import SFSafariViewController from 'react-native-sfsafariviewcontroller'
import { logEvent } from '@common/CanvasAnalytics'

const developerMenuStorageKey = 'teacher.profile.developermenu'

type State = {
  avatarURL: string,
  showsDeveloperMenu: boolean,
}

export class Profile extends Component<Object, State> {
  static defaultProps = {
    account: canvas.account,
    getUserProfile: canvas.getUserProfile,
  }

  secretTapCount: number
  settingsActions: { title: string, id: string }[]

  constructor (props: any) {
    super(props)
    this.secretTapCount = 0

    const settingsActions = [
      { title: i18n('Visit the Canvas Guides'), id: 'canvas-guides' },
    ]

    settingsActions.push({ title: i18n('Terms of Use'), id: 'terms' })
    settingsActions.push({ title: i18n('Cancel'), id: 'cancel' })
    this.settingsActions = settingsActions

    let session = getSession()
    this.state = {
      avatarURL: session.user.avatar_url || '',
      showsDeveloperMenu: false,
    }
  }

  componentDidMount () {
    this.props.refreshCanMasquerade()
    this.props.refreshAccountExternalTools()
    this.props.refreshHelpLinks()
    this.refreshAvatarURL()
    this.enableDeveloperMenu()
  }

  refreshAvatarURL = async () => {
    try {
      const { data } = await this.props.getUserProfile('self')
      if (data && data.avatar_url) {
        this.setState({ avatarURL: data.avatar_url })
      }
    } catch (e) {}
  }

  logout = () => {
    purgeUserStoreData()
    httpCache.purgeUserData()
    NativeModules.NativeLogin.logout()
  }

  async launchExternalTool (url: string) {
    await this.props.navigator.dismiss()
    LTITools.launchExternalTool(url)
  }

  switchUser = () => {
    logEvent('change_user_selected')
    NativeModules.NativeLogin.switchUser()
  }

  toggleMasquerade = async () => {
    let session = getSession()
    await this.props.navigator.dismiss()
    if (session.actAsUserID) {
      NativeModules.NativeLogin.stopMasquerade()
    } else {
      this.props.navigator.show('/masquerade', { modal: true })
    }
  }

  secretTap = async () => {
    this.secretTapCount++
    if (this.secretTapCount > 10) {
      this.secretTapCount = 0
      LayoutAnimation.easeInEaseOut()

      let enabled = await AsyncStorage.getItem(developerMenuStorageKey)
      if (enabled) {
        AsyncStorage.removeItem(developerMenuStorageKey)
      } else {
        AsyncStorage.setItem(developerMenuStorageKey, 'enabled')
      }
      this.enableDeveloperMenu()
    }
  }

  enableDeveloperMenu = async () => {
    if (global.__DEV__) {
      this.setState({
        showsDeveloperMenu: true,
      })
    } else {
      let enabled = await AsyncStorage.getItem(developerMenuStorageKey)
      this.setState({
        showsDeveloperMenu: enabled,
      })
    }
  }

  showDeveloperMenu = async () => {
    await this.props.navigator.dismiss()
    this.props.navigator.show('/dev-menu', { modal: true })
  }

  settings = async () => {
    await this.props.navigator.dismiss()
    if (isStudent()) {
      this.props.navigator.show('/profile/settings', { modal: true })
    } else {
      ActionSheetIOS.showActionSheetWithOptions({
        options: this.settingsActions.map(a => a.title),
        cancelButtonIndex: this.settingsActions.length - 1,
      }, this.handleActions)
    }
  }

  userFiles = async () => {
    await this.props.navigator.dismiss()
    this.props.navigator.show('/users/self/files', { modal: false }, { customPageViewPath: '/files' })
  }

  manageObserverStudents = async () => {
    await this.props.navigator.dismiss()
    this.props.navigator.show('/parent/manage-children', { modal: false })
  }

  toggleShowGrades = () => {
    this.props.updateShowGradesOnDashboard(!this.props.showsGradesOnCourseCards)
  }

  handleActions = async (index: number) => {
    const action = this.settingsActions[index]
    switch (action.id) {
      case 'canvas-guides':
        Linking.openURL('https://community.canvaslms.com/community/answers/guides/mobile-guide/content?filterID=contentstatus%5Bpublished%5D~category%5Btable-of-contents%5D')
        break
      case 'terms':
        await this.props.navigator.dismiss()
        this.props.navigator.show('/terms-of-use', { modal: true })
        break
      default:
        break
    }
  }

  showHelpMenu = () => {
    const { helpLinks } = this.props
    if (!helpLinks) return
    const { custom_help_links, default_help_links, help_link_name } = helpLinks
    let links = custom_help_links.length ? custom_help_links : default_help_links
    links = links.filter((link) => {
      const role = isStudent() ? 'student' : 'teacher' // parent has their own help menu
      return link.available_to.includes('user') || link.available_to.includes(role)
    })
    const options = [...links.map(l => l.text), i18n('Cancel')]
    ActionSheetIOS.showActionSheetWithOptions({
      title: help_link_name,
      options,
      cancelButtonIndex: options.length - 1,
    }, async (pressedIndex: number) => {
      if (pressedIndex === (options.length - 1)) return
      // the profile itself is presented modally
      // must dismiss before showing another modal
      await this.props.navigator.dismiss()

      const link = links[pressedIndex]
      switch (link.id) {
        case 'instructor_question':
          this.props.navigator.show('/conversations/compose', { modal: true }, {
            instructorQuestion: true,
            canAddRecipients: false,
          })
          break
        case 'report_a_problem':
          this.props.navigator.show('/support/problem', { modal: true })
          break
        default:
          this.props.navigator.showWebView(link.url)
          break
      }
    })
  }

  showParentHelpMenu = () => {
    let options = [
      i18n('View Canvas Guides'),
      i18n('Report a Problem'),
      i18n('Request a Feature'),
      i18n('Terms of Use'),
      i18n('Cancel'),
    ]
    ActionSheetIOS.showActionSheetWithOptions({
      title: i18n('Help'),
      options,
      cancelButtonIndex: 4,
    }, async (pressedIndex: number) => {
      if (pressedIndex === (options.length - 1)) return
      // the profile itself is presented modally
      // must dismiss before showing another modal
      await this.props.navigator.dismiss()

      switch (pressedIndex) {
        case 0:
          SFSafariViewController.open('https://community.canvaslms.com/docs/DOC-9919')
          break
        case 1:
          this.props.navigator.show('/support/problem', { modal: true })
          break
        case 2:
          this.props.navigator.show('/support/feature', { modal: true })
          break
        case 3:
          this.props.navigator.show('/terms-of-use', { modal: true })
          break
      }
    })
  }

  renderList = () => {
    let titleStyles = { fontSize: 20, fontWeight: '300' }
    let session = getSession()
    let externalTools = (this.props.externalTools || [])

    const buildRow = (title: string, onPress: ?Function, switchProps?: ?Object, testIDProps?: Object = {}) => {
      return (<View key={testIDProps.testID || title}>
        { onPress && <Row title={title} titleStyles={titleStyles} onPress={onPress} {...testIDProps} />}
        { switchProps && Object.keys(switchProps).length > 0 && <RowWithSwitch title={title} titleStyles={titleStyles} {...switchProps} />}
        <RowSeparator style={styles.separator} />
      </View>)
    }

    const masquerading = !!session.actAsUserID
    const masqueradeTitle = masquerading ? i18n('Stop Act as User') : i18n('Act as User')
    let tools
    if (externalTools.length > 0) {
      tools = externalTools.map((tool) => {
        if (!tool.placements || !tool.placements.global_navigation) return null
        const { title, url } = tool.placements.global_navigation
        const onPress = () => { this.launchExternalTool(url) }
        return buildRow(title, onPress, null, { testID: `row-lti-${tool.domain}-${tool.definition_id}` })
      }).filter(Boolean)
    }

    if (isParent()) {
      return (<View>
        { buildRow(i18n('Manage Children'), this.manageObserverStudents)}
        { buildRow(i18n('Help'), this.showParentHelpMenu) }
        { (this.props.canMasquerade || masquerading) && buildRow(masqueradeTitle, this.toggleMasquerade) }
        { this.state.showsDeveloperMenu && buildRow(i18n('Developer Menu'), this.showDeveloperMenu) }
        { !masquerading && buildRow(i18n('Change User'), this.switchUser) }
        { !masquerading && buildRow(i18n('Log Out'), this.logout) }
      </View>)
    }

    return (<View>
      { buildRow(i18n('Files'), this.userFiles) }
      { tools }
      { (this.props.canMasquerade || masquerading) && buildRow(masqueradeTitle, this.toggleMasquerade) }
      { isStudent() && buildRow(i18n('Show Grades'), null, { onValueChange: this.toggleShowGrades, value: this.props.showsGradesOnCourseCards }) }
      { this.props.helpLinks && buildRow(this.props.helpLinks.help_link_name, this.showHelpMenu, null, { testID: 'profile.help-menu-btn' }) }
      { !isParent() && buildRow(i18n('Settings'), this.settings, null, { testID: 'profile.settings-btn' }) }
      { this.state.showsDeveloperMenu && buildRow(i18n('Developer Menu'), this.showDeveloperMenu) }
      { !masquerading && buildRow(i18n('Change User'), this.switchUser) }
      { !masquerading && buildRow(i18n('Log Out'), this.logout) }
    </View>)
  }

  renderHeader (user: SessionUser) {
    return (
      <View style={styles.header}>
        <Avatar
          avatarURL={this.state.avatarURL}
          userName={user.name}
          height={56}
          width={56}
          testID='profile.avatar'
        />
      </View>
    )
  }

  render () {
    const session = getSession()
    const user = session.user
    const name = user.short_name || user.name
    return (
      <Screen
        navBarHidden
        navBarButtonColor={color.link}
        disableGlobalSafeArea
      >
        <View style={styles.container} testID="module.profile">
          <StatusBar />
          <SafeAreaView style={{ flex: 1 }}>
            { this.renderHeader(user) }
            <View style={styles.infoHeader}>
              { !!name && <Heavy style={styles.name} allowFontScaling={false}>{name}</Heavy> }
              { !!user.primary_email && <Paragraph style={styles.email} allowFontScaling={false}>{user.primary_email}</Paragraph> }
            </View>
            <ScrollView>
              { this.renderList() }
            </ScrollView>
            <View style={styles.versionContainer}>
              <TouchableWithoutFeedback onPress={this.secretTap} testID='profile-btn-secret-tap'>
                { /* I removed localization for this because i highly doubt a translator will know what v. is */ }
                <Text style={styles.versionText}>{`v. ${device.getVersion()}`}</Text>
              </TouchableWithoutFeedback>
            </View>
          </SafeAreaView>
        </View>
      </Screen>
    )
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: global.style.defaultPadding,
  },
  infoHeader: {
    paddingLeft: global.style.defaultPadding,
    paddingBottom: global.style.defaultPadding,
  },
  name: {
    fontSize: 24,
  },
  email: {
    fontSize: 16,
  },
  separator: {
    marginLeft: 16,
  },
  versionContainer: {
    bottom: 0,
    padding: global.style.defaultPadding,
  },
  versionText: {
    color: '#73818C',
    fontSize: 12,
  },
})

export function mapStateToProps (state: AppState): UserInfo {
  return state.userInfo
}

let Connected = connect(mapStateToProps, { ...Actions })(Profile)
export default Connected
