

import Foundation

enum MoneyMoneyError: Error {
    case DatabaseLocked
    case NotFound
    case Other(reason: String)
}


class MoneyMoneyApi {
    
    static func sentInvoice(sourceIban: String, giroCode: GiroCode) throws {
        let line1 = "tell application \"MoneyMoney\"\n"
        let line2 = "  create bank transfer from account \"\(sourceIban)\" to \"\(giroCode.recipientName)\" iban \"\(giroCode.recipientIban)\" amount \(giroCode.amount) purpose \"\(giroCode.purpose ?? "")\"\n"
        let line3 = "end tell\n"
        let script = line1+line2+line3
        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: script)
        _ = scriptObject!.executeAndReturnError(&error)
        if let error = error {
            throw moneyMoneyError(error)
        }
    }
    
    static func getAccounts() throws -> [Account] {
        let line1 = "tell application \"MoneyMoney\"\n"
        let line2 = "  export accounts\n"
        let line3 = "end tell\n"
        let script = line1+line2+line3
        var error: NSDictionary?
        let scriptObject = NSAppleScript(source: script)
        let result = scriptObject!.executeAndReturnError(&error)
        if let error = error {
            throw moneyMoneyError(error)
        } else {
            let parser = AccountParser()
            return parser.parse(data: result.data)
        }
    }
    
    static func moneyMoneyError(_ error: NSDictionary) -> MoneyMoneyError {
        let errorMsg = error["NSAppleScriptErrorMessage"] as! String
        if (errorMsg == "MoneyMoney got an error: Locked database.") {
            return MoneyMoneyError.DatabaseLocked
        }
        else if (errorMsg == "Expected end of line but found identifier.") {
            return MoneyMoneyError.NotFound
        }
        else {
            return MoneyMoneyError.Other(reason: errorMsg)
        }
    }
}
