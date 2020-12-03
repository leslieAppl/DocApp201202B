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
    var files = [URL]() //Optional files url

    //UIDocument & Data model properties
    var doc : PeopleDocument?
    var people : [Person] { // point to the document's model object
        get { return self.doc!.people }
        set { self.doc!.people = newValue }
    }
    
    @IBOutlet weak var listView: UITextView!
    
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
        listView.text = ""
        listFiles()
    }
}

//MARK: - Business Logic
extension ViewController {
    
    //TODO: -0 Listing file names
    func listFiles() {
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
        
        //Using alert view to create file name.
        let av = UIAlertController(title: "New Group", message: "Enter name", preferredStyle: .alert)
        av.addTextField { (text) in
            text.autocapitalizationType = .words
        }
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        av.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            
            guard let name = av.textFields![0].text, !name.isEmpty else {return}
            print("New file name is \(name)")
            
            //Creating File URL
            self.fileURL = self.docsURL.appendingPathComponent((name as NSString).appendingPathExtension("pplgrp")!)
            // really should check to see if file by this name exists

            print("0. created file url: \(String(describing: self.fileURL!.deletingLastPathComponent()))\(String(describing: self.fileURL!.lastPathComponent))")
            self.doAddData()
            self.files.append(self.fileURL!)    //Optional
//            print(self.files)
        }))
        
        self.present(av, animated: true)
    }
    
    //TODO: -2 Create OR Open A Document File
    func doAddData() {
        
        guard let fileURL = fileURL else { return }
        //1- Init UIDocument instance with the file url
        self.doc = PeopleDocument(fileURL: fileURL)
        print("1. Inited UIDocument instance of \(fileURL.lastPathComponent).")
        //2- Checking URL...
        //If the URL existed, opens a document asynchronously.
        //If not existed, Saves document data to the specified location.
        if let _ = try? fileURL.checkResourceIsReachable() {
            self.doc?.open()
            //Calling uidocument.load(fromContents: ofType:) to load document's data
            print("2.1 Opening \(fileURL.lastPathComponent)")
            
            readData()
            
        } else {
            //Creating new data
            self.doc!.save(to:self.doc!.fileURL,
                          for: .forCreating) //for creating a new document file with empty data content in it.
            //Calling uidocument.contents(forType:) to save data to the document
            print("2.2 Created document file \(fileURL.lastPathComponent)")
            
            addData()
            
            //4- UIDocument updating data
            self.doc?.updateChangeCount(.done)
            print("4. Updating Document's data..")
        }

        

    }
    
    //TODO: -3 Creating Data Model Object
    func addData() {
        let newP = Person(firstName: "Test", lastName: "Leslie")
        self.people.append(newP)
        print("3. New file data created in the \(self.fileURL!.lastPathComponent)..")
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
