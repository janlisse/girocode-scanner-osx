

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
        callReadAccountsScript()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func callReadAccountsScript() {
        let line1 = "tell application \"MoneyMoney\"\n"
        let line2 = "  export accounts\n"
        let line3 = "end tell\n"
        let script = line1+line2+line3
        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: script)
        let result = scriptObject!.executeAndReturnError(&error)
        if let error = error {
            print(error)
            errorMsgLabel.stringValue = "Error: \(error.value(forKey: "NSAppleScriptErrorBriefMessage") as! String)"
            accountsList.insertItem(withTitle: "-", at: 0)
            return
        }
        let parser = AccountParser()
        let accounts = parser.parse(data: result.data)
        accountsList.addItems(withTitles: Array(accounts.keys))
        
    }
}
