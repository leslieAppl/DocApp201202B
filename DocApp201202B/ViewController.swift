//
//  ViewController.swift
//  DocApp201202B
//
//  Created by leslie on 12/2/20.
//

import UIKit

class ViewController: UIViewController {
    
    //File Manager & URL properties
    let fm = FileManager.default
    var docsURL: URL {
        do {
            return try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
            print(error)
        }
        
        return NSURL() as URL // shouldn't happen
    }
    var fileURL : URL?
    var files = [URL]() //Optional

    //UIDocument & Data model properties
    var doc : PeopleDocument?
    var people : [Person] { // point to the document's model object
        get { return self.doc!.people }
        set { self.doc!.people = newValue }
    }
    
    @IBOutlet weak var listView: UITextView!
    @IBOutlet weak var statusBar: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let b = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(doAddFile(_:)))
        self.navigationItem.rightBarButtonItems = [b]
        self.title = "Group"
        
        listFiles()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(forceSave), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.forceSave(nil)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func listRefreshBtnPressed(_ sender: UIButton) {
        listFiles()
    }
}

//MARK: - Business Logic
extension ViewController {
    
    //TODO: -0 Listing file names
    func listFiles() {
        listView.text = ""  //clean view first

        do {
            let files = try fm.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil).filter({ (url) -> Bool in
                return url.pathExtension == "pplgrp"
            })
            
            for file in files {
                let fileName = file.lastPathComponent
                listView.text += "\(fileName)\n"
            }
            
        } catch {
            print(error)
        }
    }
    
    

    //TODO: -1 Creating File URL.
    @objc func doAddFile(_: Any) {
        
        self.statusBar.text = ""    //clean status bar first
        
        //1 Using alert view to create file name.
        let av = UIAlertController(title: "New Group", message: "Enter name", preferredStyle: .alert)
        av.addTextField { (text) in
            text.autocapitalizationType = .words
        }
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        av.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            
            guard let name = av.textFields![0].text, !name.isEmpty else {return}
            
            //2 Creating File URL with the file name.
            self.fileURL = self.docsURL.appendingPathComponent((name as NSString).appendingPathExtension("pplgrp")!)
            
            // really should check to see if file by this name exists
            guard let fileURL = self.fileURL else { return }
            
            if let _ = try? fileURL.checkResourceIsReachable() {

                //alerting file name duplicated
                let av = UIAlertController(title: "File Name Duplicated", message: "Please change the file name", preferredStyle: .alert)
                av.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(av, animated: true, completion: nil)
            }
            else {
                //3 Init UIDocument instance including empty data
                self.doc = PeopleDocument(fileURL: fileURL)
                
                //4 Saving data to document .forCreating
                self.doc!.save(to: self.doc!.fileURL, for: .forCreating, completionHandler: nil)
                
                self.statusBar.text = "Created document: \(fileURL.lastPathComponent)"
                self.files.append(self.fileURL!)    //Optional
            }
        }))
        
        self.present(av, animated: true)
        
//        self.listFiles()
        //Note: Archiving document will lead to time interal delay! So, you cann't scan out new created file as soon as saving the new file.
    }
    
    
    //TODO: -3 Creating Data Model Object
    func doAddData() {
        let newP = Person(firstName: "Test", lastName: "Leslie")
        self.people.append(newP)
        print("3. New file data created in the \(self.fileURL!.lastPathComponent)..")
        
        //4- UIDocument updating data
        self.doc?.updateChangeCount(.done)
        print("4. Updating Document's data..")
    }
    
    //TODO: -4 Reading data from document
    func readData() {
        guard let fileURL = fileURL else { return }
        let doc = PeopleDocument(fileURL: fileURL)
        doc.open { (success) in
            //Do sth after opening and loading data from document
            let people = doc.people
            for person in people {
                print("Opened document \"\(fileURL.lastPathComponent)\" and read data: \(person)")
            }
        }
    }

    //TODO: -5 Force Saving
    @objc func forceSave(_: Any?) {
        guard let doc = self.doc
        else {
            print("Underground force saving: uidocument subclass instance negative.")
            return
        }
        doc.save(to: doc.fileURL, for: .forOverwriting)
        print("force saving")
    }
    

}
