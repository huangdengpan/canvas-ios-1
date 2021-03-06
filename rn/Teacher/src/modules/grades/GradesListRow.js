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

// @flow

import React, { PureComponent } from 'react'
import {
  View,
  StyleSheet,
} from 'react-native'

import AccessIcon from '../../common/components/AccessIcon'
import Row from '../../common/components/rows/Row'
import Images from '../../images'
import { statusProp, dueDate } from '../submissions/list/get-submissions-props'
import SubmissionStatusLabel from '../submissions/list/SubmissionStatusLabel'
import { submissionTypeIsOnline } from '@common/submissionTypes'
import { Text } from '@common/text'
import { formatStudentGrade } from '@common/formatters'

type Props = {
  assignment: Assignment,
  tintColor?: string,
  onPress?: (Assignment) => void,
  selected?: boolean,
  user?: SessionUser,
}

export default class GradesListRow extends PureComponent<Props> {
  onPress = () => {
    const { assignment, onPress } = this.props
    onPress && onPress(assignment)
  }

  render () {
    const { assignment, selected, user } = this.props
    const { submission } = assignment
    const onlineSubmissionType = assignment.submission_types.every(submissionTypeIsOnline)
    const grade = formatStudentGrade(assignment)
    const status = statusProp(submission, dueDate(assignment, user))
    return (
      <Row
        renderImage={this._renderIcon}
        title={assignment.name}
        titleProps={{ ellipsizeMode: 'tail', numberOfLines: 2 }}
        border='bottom'
        disclosureIndicator
        testID={`grades-list.grades-list-row.cell-${assignment.id}`}
        onPress={this.onPress}
        selected={selected}
        height='auto'
        accessories={
          <Text style={styles.gradeText}>{grade}</Text>
        }
      >
        {status && assignment.grading_type !== 'not_graded' &&
          <SubmissionStatusLabel status={status} onlineSubmissionType={onlineSubmissionType} />
        }
      </Row>
    )
  }

  _renderIcon = () => {
    const assignment = this.props.assignment
    let image = Images.course.assignments
    let testIDSuffix = `-icon-${assignment.published ? 'published' : 'not-published'}-${assignment.id}.icon-img`
    let testID = `grades-list-row-assignment${testIDSuffix}`
    if (assignment.submission_types.includes('online_quiz')) {
      image = Images.course.quizzes
      testID = `grades-list-row-quiz${testIDSuffix}`
    } else if (assignment.submission_types.includes('discussion_topic')) {
      image = Images.course.discussions
      testID = `grades-list-row-discussion${testIDSuffix}`
    }
    return (
      <View style={styles.icon} testID={testID}>
        <AccessIcon entry={assignment} tintColor={this.props.tintColor} style={styles.icon} image={image} />
      </View>
    )
  }
}

const styles = StyleSheet.create({
  ungradedText: {
    flex: 0,
    alignSelf: 'flex-start',
    fontSize: 11,
    fontWeight: '600',
    color: '#008EE2',
    borderRadius: 9,
    borderColor: '#008EE2',
    borderWidth: 1,
    backgroundColor: 'white',
    paddingTop: 3,
    paddingBottom: 1,
    paddingLeft: 6,
    paddingRight: 6,
    marginTop: 4,
    overflow: 'hidden',
  },
  gradeText: {
    fontSize: 14,
    fontWeight: '600',
    alignSelf: 'center',
  },
  icon: {
    alignSelf: 'flex-start',
  },
})
