

import Foundation
import Cocoa


class GiroCodeListController : NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    var giroCodes = [GiroCode(recipientName: "Hans", recipientIban: "DE234345", amount: 200.00, purpose: nil, wasSent: false),
                     GiroCode(recipientName: "Werner", recipientIban: "DE78934232345", amount: 1500.00, purpose: nil, wasSent : true)]
    
    let checkmarkImage = Bundle.main.image(forResource: "checkmark")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
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
            cell.textField?.stringValue = code.recipientIban
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
