

import Foundation

struct Account {
    let name: String
    let number: String
}

class AccountParser: NSObject, XMLParserDelegate {
    
    var currentElement: String?
    var currentKey: String?
    var lastAccountNumber: String?
    var lastName: String?
    var accounts: [Account] = []
    
    
    func parse(data: Data) -> [Account] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return accounts
    }
    
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: CharacterSet(charactersIn: "\n\t"))
        if (currentElement == "key" && !trimmed.isEmpty) {
            currentKey = trimmed
        }
        if (currentElement == "string" && currentKey == "accountNumber" && !trimmed.isEmpty) {
            lastAccountNumber = trimmed
            
        }
        if (currentElement == "string" && currentKey == "name" && !trimmed.isEmpty) {
            lastName = trimmed
            if let lastAccountNumber = lastAccountNumber {
                accounts.append(Account(name: trimmed, number: lastAccountNumber))
            }
        }
    }
}
