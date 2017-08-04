

import Foundation

class MoneyMonpeyApi {
    
    static func callInvoiceScript(sourceIban: String, recipientName: String, recipientIban: String, amount: Double, purpose: String) {
        let line1 = "tell application \"MoneyMoney\"\n"
        let line2 = "  create bank transfer from account \"\(sourceIban)\" to \"\(recipientName)\" iban \"\(recipientIban)\" amount \(amount) purpose \"\(purpose)\"\n"
        let line3 = "end tell\n"
        let script = line1+line2+line3
        var error: NSDictionary?
        print(script)
        let scriptObject = NSAppleScript(source: script)
        _ = scriptObject!.executeAndReturnError(&error)
        if let error = error {
            print(error)
        } else {
            print("Successfully sent invoice")
        }
    }
    
    static func callReadAccountsScript() -> [String : String] {
        let line1 = "tell application \"MoneyMoney\"\n"
        let line2 = "  export accounts\n"
        let line3 = "end tell\n"
        let script = line1+line2+line3
        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: script)
        let result = scriptObject!.executeAndReturnError(&error)
        if let error = error {
            print(error)
            return [:]
        }
        let parser = AccountParser()
        return parser.parse(data: result.data)
    }
}
