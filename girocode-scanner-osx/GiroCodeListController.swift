

import Foundation
import Cocoa


class GiroCodeListController : NSViewController {
    
    var giroCodes = [GiroCode]()
    let checkmarkImage = Bundle.main.image(forResource: "checkmark")
    
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var accountSelection: NSPopUpButton!
    @IBOutlet weak var accountLabel: NSTextField!
    @IBOutlet weak var accountSelectionView: NSView!
    @IBOutlet weak var errorView: NSView!
    
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
        catch {
            showError(msg: "Other error")
        }
    }
    
    private func showError(msg: String) {
        toggleSplitView(showError: true)
    }
    
    private func toggleSplitView(showError: Bool) {
        accountSelectionView.isHidden = showError
        errorView.isHidden = !showError
        splitView.adjustSubviews()
    }
    
    func tableViewDoubleClick(_ sender:AnyObject) {
        
        if tableView.selectedRow >= 0 {
            let giroCode = giroCodes[tableView.selectedRow]
            if let account = accountSelection.titleOfSelectedItem {
                if (!giroCode.wasSent) {
                    do {
                        try MoneyMoneyApi.sentInvoice(sourceIban: account, giroCode: giroCode)
                        giroCodes[tableView.selectedRow].wasSent = true
                        self.tableView.reloadData()
                    }
                    catch MoneyMoneyError.DatabaseLocked {
                        print("Please unlock MoneyMoney DB.")
                    }
                    catch {
                        print("Other error")
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
        
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
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
