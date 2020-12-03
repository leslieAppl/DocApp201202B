//
//  PeopleDocument.swift
//  DocApp201202B
//
//  Created by leslie on 12/2/20.
//

import UIKit

class PeopleDocument: UIDocument {
    
    //Data modle for the Document
    var people = [Person]()
    
    override func load(fromContents contents: Any,
        ofType typeName: String?) throws {
            print("loading \(typeName as Any)")
            if let contents = contents as? Data {
                //Decoding data modle from NSdata Type in the Document.
                if let arr = try? PropertyListDecoder().decode([Person].self, from: contents) {
                    self.people = arr
                    print("loaded \(self.people)")
                    return // all's well that ends well
                }
            }
            // if we get here, there was some kind of problem
            throw NSError(domain: "NoDataDomain", code: -1, userInfo: nil)
    }
    
    override func contents(forType typeName: String) throws -> Any {
        print("archiving \(typeName)")
        //Encoding data modle to NSData Type for saving it to the Document.
        if let data = try? PropertyListEncoder().encode(self.people) {
            return data
        }
        // if we get here, there was some kind of problem
        throw NSError(domain: "NoDataDomain", code: -2, userInfo: nil)
    }
        
}


