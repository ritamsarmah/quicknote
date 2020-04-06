//
//  ViewController.swift
//  QuickNote
//
//  Created by Ritam Sarmah on 4/4/20.
//  Copyright © 2020 Ritam Sarmah. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var bodyTextView: PlaceholderTextView!
    @IBOutlet weak var folderPopUpButton: NSPopUpButton!
    @IBOutlet weak var autoTitleButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    
    var appDelegate: AppDelegate {
        return NSApplication.shared.delegate as! AppDelegate
    }
    
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var defaultTitle: String {
        return "Note \(ViewController.dateFormatter.string(from: Date()))"
    }
    
    var defaultFont = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveButton.isEnabled = !bodyTextView.string.isEmpty
        
        bodyTextView.delegate = self
        bodyTextView.wantsLayer = true
        bodyTextView.layer?.cornerRadius = 4
        bodyTextView.textContainerInset = NSSize(width: 2, height: 8)
        bodyTextView.font = defaultFont
        bodyTextView.textStorage?.font = defaultFont
        bodyTextView.placeholderAttributedString = NSAttributedString(string: "Type something...", attributes: [
            NSAttributedString.Key.font : defaultFont,
            NSAttributedString.Key.foregroundColor : NSColor.gray
        ])
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        folderPopUpButton.menu?.addItem(withTitle: "Notes", action: nil, keyEquivalent: "") // Temporary default value
        
        DispatchQueue.global(qos: .userInitiated).async {
            let folders = Notes.shared.folders
            
            DispatchQueue.main.async {
                self.folderPopUpButton.menu?.removeAllItems()
                folders.forEach { folder in
                    self.folderPopUpButton.menu?.addItem(withTitle: folder,
                                                         action: nil,
                                                         keyEquivalent: "")
                }
                self.folderPopUpButton.selectItem(withTitle: "Notes")
            }
        }
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        appDelegate.closePopover(sender: self)
        resetNote()
        
    }
    
    @IBAction func save(_ sender: NSButton) {
        var title: String
        var body: String
        
        let lines = bodyTextView.string.split(separator: "\n").map { String($0) }
        
        if autoTitleButton.state == .on {
            title = defaultTitle
            body = bodyTextView.string
        } else {
            title = lines.count == 1 ? bodyTextView.string : lines[0]
            body = lines.count == 1 ? "" : lines[1...].joined(separator: "\n")
        }
        
        do {
            try Notes.shared.createNote(title: title,
                                        body: body,
                                        folder: folderPopUpButton.selectedItem!.title)
        } catch let error {
            presentError(error)
        }
        
        resetNote()
        appDelegate.closePopover(sender: self)
    }
    
    func resetNote() {
        bodyTextView.string = ""
    }
}

extension ViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        saveButton.isEnabled = !textView.string.isEmpty
    }
}


extension ViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> ViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("ViewController")
        
        guard let vc = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
            fatalError("Couldn't find ViewController in Main.storyboard")
        }
        
        return vc
    }
}
