

import Foundation
import Cocoa


class AccountSelectionController: NSViewController {
    
    @IBOutlet weak var accountsList: NSPopUpButton!
    @IBOutlet weak var errorMsgLabel: NSTextField!
    
    @IBAction func accountListAction(_ sender: Any) {
        if let account = accountsList.titleOfSelectedItem {
            if (account != "-") {
                // enable capture button
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GradientUtil.setGradientGreenBlue(view : self.view)
        let accounts = MoneyMonpeyApi.callReadAccountsScript()
        accountsList.addItems(withTitles: Array(accounts.keys))
        //TODO handle error
        //errorMsgLabel.stringValue = "Error: \(error.value(forKey: "NSAppleScriptErrorBriefMessage") as! String)"
        //accountsList.insertItem(withTitle: "-", at: 0)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
}
