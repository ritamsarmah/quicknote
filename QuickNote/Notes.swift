//
//  Notes.swift
//  QuickNote
//
//  Created by Ritam Sarmah on 4/4/20.
//  Copyright © 2020 Ritam Sarmah. All rights reserved.
//

import Down
import Foundation

class Notes {
    
    static let shared = Notes()
    
    private init() {}
    
    var folders: [String] {
        let source = """
        tell application "Notes"
           return (name of every folder whose name is not "Recently Deleted")
        end tell
        """
        
        let script = NSAppleScript(source: source)!
        var error: NSDictionary?
        
        let result = script.executeAndReturnError(&error).coerce(toDescriptorType: typeAEList)!
        
        if let error = error {
            print(error)
            return []
        } else {
            var folders = [String]()
            
            (1...result.numberOfItems).forEach {
                folders.append(result.atIndex($0)!.stringValue!)
            }
            
            return folders
        }
    }
    
    func createNote(title: String, body: String, folder: String = "Notes") throws {
        do {
            let escapedBody = body
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\"", with: "\\\"")
            let down = Down(markdownString: escapedBody)
            let html = try down.toHTML([.hardBreaks, .smart, .validateUTF8])
            
            let source = """
            tell application "Notes"
                activate
                tell default account to tell folder "\(folder)"
                    make new note with properties {name:"\(title)", body:"\(html)"}
                    show note 1
                end tell
            end tell
            """
            
            let script = NSAppleScript(source: source)!
            var error: NSDictionary?
            
            DispatchQueue.global(qos: .userInitiated).async {
                script.executeAndReturnError(&error)
                if let error = error {
                    print(error)
                }
            }
        } catch let error {
            throw error
        }
    }
    
}
