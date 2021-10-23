

import Foundation
import Cocoa


class GiroCodeListController : NSViewController {
    
    var giroCodes = [GiroCode]()
    let checkmarkImage = Bundle.main.image(forResource: NSImage.Name(rawValue: "checkmark"))
    let successSound = NSSound(named: NSSound.Name(rawValue: "success"))
    
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var accountSelection: NSPopUpButton!
    @IBOutlet weak var accountSelectionView: NSView!
    @IBOutlet weak var errorView: NSView!
    @IBOutlet weak var errorLabel: NSTextField!
    @IBAction func retryButtonClicked(_ sender: Any) {
        loadAccounts()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClick(_:))
        NotificationCenter.default.addObserver(forName: ScanController.notificationName, object: nil, queue: nil){
            notification in
            let giroCode = notification.userInfo?["giroCode"] as! GiroCode
            self.giroCodes.append(giroCode)
            self.tableView.reloadData()
        }
        loadAccounts()

    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    private func loadAccounts() {
        do {
            let accounts = try MoneyMoneyApi.getAccounts()
            accountSelection.addItems(withTitles: Array(accounts.map{ a in a.name}))
            toggleSplitView(showError: false)
            
        }
        catch MoneyMoneyError.DatabaseLocked {
            showError(msg: "Error: Please unlock MoneyMoney DB.")
        }
        catch MoneyMoneyError.NotFound {
            showError(msg: "Error: MoneyMoney not found.")
        }
        catch MoneyMoneyError.Other(let reason){
            showError(msg: reason)
        }
        catch {
            showError(msg: "Unknown error")
        }
    }
    
    private func showError(msg: String) {
        errorLabel.stringValue = msg
        toggleSplitView(showError: true)
    }
    
    private func toggleSplitView(showError: Bool) {
        accountSelectionView.isHidden = showError
        errorView.isHidden = !showError
        splitView.adjustSubviews()
    }
    
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        if tableView.selectedRow >= 0 {
            let giroCode = giroCodes[tableView.selectedRow]
            if let account = accountSelection.titleOfSelectedItem {
                if (!giroCode.wasSent) {
                    if (try? MoneyMoneyApi.sentInvoice(sourceIban: account, giroCode: giroCode)) != nil {
                        giroCodes[tableView.selectedRow].wasSent = true
                        self.tableView.reloadData()
                        successSound?.play()
                    }
                }
            }
        }
    }
}

extension GiroCodeListController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return giroCodes.count
    }
}

extension GiroCodeListController: NSTableViewDelegate {
    fileprivate enum CellIdentifiers {
        static let NameCell = "ImageTextCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let code = giroCodes[row]
        let cellIdentifier = CellIdentifiers.NameCell
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = "Recipient: \(code.recipientName), Amount: \(code.amount)"
            if (code.wasSent) {
                cell.imageView?.image = checkmarkImage
            } else {
                cell.imageView?.image = nil
            }
            return cell
        }
        return nil
    }
}


extension GiroCodeListController: NSSplitViewDelegate {
    
    func splitView(_ splitView: NSSplitView,
                   shouldHideDividerAt dividerIndex: Int)-> Bool {
        return true
    }
    
    func splitView(_ splitView: NSSplitView,
                   effectiveRect proposedEffectiveRect: NSRect,
                   forDrawnRect drawnRect: NSRect,
                   ofDividerAt dividerIndex: Int) -> NSRect{
        return NSRect.init()
    }
    
}
