

import Foundation
import Cocoa


class GiroCodeListController : NSViewController {
    
    var giroCodes = [GiroCode]()
    let checkmarkImage = Bundle.main.image(forResource: "checkmark")
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var accountSelection: NSPopUpButton!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let accounts = MoneyMoneyApi.callReadAccountsScript()
        accountSelection.addItems(withTitles: Array(accounts.keys))
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
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func tableViewDoubleClick(_ sender:AnyObject) {
        
        if tableView.selectedRow >= 0 {
            let giroCode = giroCodes[tableView.selectedRow]
            if let account = accountSelection.titleOfSelectedItem {
                if (!giroCode.wasSent) {
                    MoneyMoneyApi.callInvoiceScript(sourceIban: account, giroCode: giroCode)
                    giroCodes[tableView.selectedRow].wasSent = true
                    self.tableView.reloadData()
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
