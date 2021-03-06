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

import UIKit
import CoreServices
import Core

class SubmissionCommentsViewController: UIViewController, ErrorViewController {
    @IBOutlet weak var addCommentBorderView: UIView?
    @IBOutlet weak var addCommentButton: DynamicButton?
    @IBOutlet weak var addCommentPlaceholder: DynamicLabel?
    @IBOutlet weak var addCommentTextView: UITextView?
    @IBOutlet weak var addCommentView: UIView?
    @IBOutlet weak var addMediaButton: DynamicButton?
    @IBOutlet weak var addMediaHeight: NSLayoutConstraint?
    @IBOutlet weak var addMediaView: UIView?
    @IBOutlet weak var emptyLabel: DynamicLabel?
    @IBOutlet weak var keyboardSpace: NSLayoutConstraint?
    @IBOutlet weak var tableView: UITableView?

    var currentUserID: String?
    var keyboard: KeyboardTransitioning?
    var presenter: SubmissionCommentsPresenter?
    var submissionPresenter: SubmissionDetailsPresenter?

    static func create(
        env: AppEnvironment = .shared,
        context: Context,
        assignmentID: String,
        userID: String,
        submissionID: String,
        submissionPresenter: SubmissionDetailsPresenter
    ) -> SubmissionCommentsViewController {
        let controller = loadFromStoryboard()
        controller.presenter = SubmissionCommentsPresenter(env: env, view: controller, context: context, assignmentID: assignmentID, userID: userID, submissionID: submissionID)
        controller.submissionPresenter = submissionPresenter
        controller.currentUserID = env.currentSession?.userID
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addCommentBorderView?.backgroundColor = .named(.backgroundLightest)
        addCommentBorderView?.layer.borderColor = UIColor.named(.borderMedium).cgColor
        addCommentBorderView?.layer.borderWidth = 1 / UIScreen.main.scale
        addCommentButton?.accessibilityLabel = NSLocalizedString("Send comment", bundle: .student, comment: "")
        addCommentTextView?.accessibilityLabel = NSLocalizedString("Add a comment or reply to previous comments", bundle: .student, comment: "")
        addCommentTextView?.font = .scaledNamedFont(.regular14)
        addCommentTextView?.adjustsFontForContentSizeCategory = true
        addCommentTextView?.textColor = .named(.textDarkest)
        emptyLabel?.isHidden = true
        emptyLabel?.text = NSLocalizedString("Have questions? Use this area to message your instructor about this assignment.", bundle: .student, comment: "")
        tableView?.transform = CGAffineTransform(scaleX: 1, y: -1)

        setInsets()
        presenter?.viewIsReady()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboard = KeyboardTransitioning(view: view, space: keyboardSpace)
    }

    func setInsets() {
        // Remember top & bottom are flipped by the transform.
        tableView?.contentInset = UIEdgeInsets(top: addCommentView?.frame.height ?? 0, left: 0, bottom: 0, right: 0)
        tableView?.scrollIndicatorInsets = UIEdgeInsets(top: addCommentView?.frame.height ?? 0, left: 0, bottom: 0, right: 0)
    }

    @IBAction func addCommentButtonPressed(_ sender: UIButton) {
        guard let textView = addCommentTextView, let text = addCommentTextView?.text.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        presenter?.addComment(text: text)
        textView.text = ""
        textViewDidChange(textView)
    }

    @IBAction func addMediaButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Record Audio", bundle: .student, comment: ""), style: .default) { [weak self] _ in
            AudioRecorderViewController.requestPermission { allowed in
                if allowed {
                    let controller = AudioRecorderViewController.create()
                    controller.delegate = self
                    self?.showMediaController(controller)
                } else {
                    self?.showPermissionError(NSLocalizedString("You must enable Microphone permissions in Settings to record audio.", bundle: .student, comment: ""))
                }
            }
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Record Video", bundle: .student, comment: ""), style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.allowsEditing = true
            picker.delegate = self
            picker.mediaTypes = [ kUTTypeMovie as String ]
            picker.sourceType = .camera
            picker.cameraDevice = .front
            self?.present(picker, animated: true)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", bundle: .student, comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    func showPermissionError(_ message: String) {
        let title = NSLocalizedString("Permission Needed", bundle: .student, comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", bundle: .student, comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Settings", bundle: .student, comment: ""), style: .default) { _ in
            guard let url = URL(string: "app-settings:") else { return }
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }

    func showMediaController(_ controller: UIViewController) {
        guard let container = addMediaView else { return }
        addCommentTextView?.resignFirstResponder()
        controller.view.alpha = 0
        embed(controller, in: container)
        UIView.animate(withDuration: 0.275, animations: {
            controller.view.alpha = 1
            self.addCommentBorderView?.alpha = 0
            self.addMediaButton?.alpha = 0
            self.addMediaHeight?.constant = 240
            self.view.layoutIfNeeded()
            self.setInsets()
        }, completion: { _ in
            self.addCommentBorderView?.isHidden = true
            self.addMediaButton?.isHidden = true
        })
    }

    func hideMediaController(_ controller: UIViewController) {
        addCommentBorderView?.isHidden = false
        addMediaButton?.isHidden = false
        UIView.animate(withDuration: 0.275, animations: {
            controller.view.alpha = 0
            self.addCommentBorderView?.alpha = 1
            self.addMediaButton?.alpha = 1
            self.addMediaHeight?.constant = 0
            self.view.layoutIfNeeded()
            self.setInsets()
        }, completion: { _ in
            controller.unembed()
        })
    }
}

extension SubmissionCommentsViewController: AudioRecorderDelegate {
    func cancel(_ controller: AudioRecorderViewController) {
        hideMediaController(controller)
    }

    func send(_ controller: AudioRecorderViewController, url: URL) {
        presenter?.addMediaComment(type: .audio, url: url)
        hideMediaController(controller)
    }
}

extension SubmissionCommentsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let url = info[.mediaURL] as? URL else { return }
        presenter?.addMediaComment(type: .video, url: url)
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension SubmissionCommentsViewController: SubmissionCommentsViewProtocol {
    func reload() {
        emptyLabel?.isHidden = presenter?.comments.isEmpty == false
        guard let changes = presenter?.comments.changes, changes.count == 1 else {
            tableView?.reloadData()
            return
        }
        switch changes[0] {
        case .insertRow(let row):
            tableView?.insertRows(at: [
                IndexPath(row: row.row * 2, section: row.section),
                IndexPath(row: row.row * 2 + 1, section: row.section),
            ], with: .automatic)
        case .updateRow(let row):
            tableView?.reloadRows(at: [
                IndexPath(row: row.row * 2, section: row.section),
                IndexPath(row: row.row * 2 + 1, section: row.section),
            ], with: .automatic)
        default:
            tableView?.reloadData()
        }
    }
}

extension SubmissionCommentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (presenter?.comments.count ?? 0) * 2 // header + content
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let comment = presenter?.comments[indexPath.row / 2] else { return UITableViewCell() }

        if indexPath.row % 2 == 1 {
            let reuseID = currentUserID == comment.authorID ? "myHeader" : "theirHeader"
            let cell: SubmissionCommentHeaderCell = tableView.dequeue(withID: reuseID, for: indexPath)
            cell.update(comment: comment)
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)
            return cell
        }

        if let attempt = comment.attempt {
            let submission = submissionPresenter?.submissions.first { $0.attempt == attempt }
            let cell: SubmissionCommentAttemptCell = tableView.dequeue(for: indexPath)
            cell.stackView?.alignment = currentUserID == comment.authorID ? .trailing : .leading
            cell.update(comment: comment, submission: submission) { [weak self] (submission: Submission?, file: File?) in
                guard let attempt = submission?.attempt else { return }
                self?.submissionPresenter?.select(attempt: attempt, fileID: file?.id)
            }
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)
            return cell
        }

        if comment.mediaURL != nil, comment.mediaType == .some(.audio) {
            let cell: SubmissionCommentAudioCell = tableView.dequeue(for: indexPath)
            cell.update(comment: comment, parent: self)
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)
            return cell
        }

        if comment.mediaURL != nil, comment.mediaType == .some(.video) {
            let cell: SubmissionCommentVideoCell = tableView.dequeue(for: indexPath)
            cell.update(comment: comment, parent: self)
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)
            return cell
        }

        let reuseID = currentUserID == comment.authorID ? "myComment" : "theirComment"
        let cell: SubmissionCommentTextCell = tableView.dequeue(withID: reuseID, for: indexPath)
        cell.update(comment: comment)
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
}

extension SubmissionCommentsViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        addCommentButton?.isEnabled = !(textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        addCommentPlaceholder?.isHidden = !textView.text.isEmpty
        setInsets()
    }
}
