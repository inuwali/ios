//
//  IssuesViewController.swift
//  FiveCalls
//
//  Created by Ben Scheirman on 1/30/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import UIKit
import Crashlytics

class IssuesViewController : UITableViewController {
    
    // keep track of when calls are made, so we know if we need to reload any cells
    var needToReloadVisibleRowsOnNextAppearance = false
    
    var issuesManager = IssuesManager()
    var logs: ContactLogs?
    
    struct ViewModel {
        let issues: [Issue]
    }
    var viewModel = ViewModel(issues: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Answers.logCustomEvent(withName:"Screen: Issues List")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadIssues()
        
        tableView.estimatedRowHeight = 75
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(forName: .callMade, object: nil, queue: nil) { [weak self] _ in
            self?.needToReloadVisibleRowsOnNextAppearance = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logs = ContactLogs.load()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // only reload rows if we need to. this fixes a rare tableview inconsistency crash we've seen
        if needToReloadVisibleRowsOnNextAppearance {
            tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [], with: .none)
            needToReloadVisibleRowsOnNextAppearance = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    func loadIssues() {
        issuesManager.userLocation = UserLocation.current
        issuesManager.fetchIssues(completion: issuesLoaded)
    }

    private func issuesLoaded() {
        viewModel = ViewModel(issues: issuesManager.issues)
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        if let typedInfo = R.segue.issuesViewController.issueSegue(segue: segue) {
            typedInfo.destination.issuesManager = issuesManager
            typedInfo.destination.issue = viewModel.issues[indexPath.row]
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.issues.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let notAButton = BorderedButton(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 26.0))
        notAButton.setTitle(R.string.localizable.whatsImportantTitle(), for: .normal)
        notAButton.setTitleColor(.fvc_darkBlueText, for: .normal)
        notAButton.backgroundColor = .fvc_superLightGray
        notAButton.borderWidth = 1
        notAButton.borderColor = .fvc_mediumGray
        notAButton.topBorder = true
        notAButton.bottomBorder = true
        return notAButton
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 26.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.issueCell, for: indexPath)!
        let issue = viewModel.issues[indexPath.row]
        cell.titleLabel.text = issue.name
        if let hasContacted = logs?.hasCompleted(issue: issue.id, allContacts: issue.contacts) {
            cell.checkboxView.isChecked = hasContacted
        }
        return cell
    }
}
