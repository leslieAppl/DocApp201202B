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
    var files = [URL]() //Optional for table view

    //UIDocument & Data model properties
    var doc : PeopleDocument?
    var people : [Person] { // point to the document's model object
        get { return self.doc!.people }
        set { self.doc!.people = newValue }
    }
    
    @IBOutlet weak var statusBar: UILabel!
    @IBOutlet weak var listView: UITextView!
    @IBOutlet weak var displayDataView: UITextView!
    
    @IBOutlet weak var openFileTxtField: UITextField!
    @IBOutlet weak var deleteFileTxtField: UITextField!
    @IBOutlet weak var firstNameTxtField: UITextField!
    @IBOutlet weak var lastNameTxtField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let b = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createFile(_:)))
        self.navigationItem.rightBarButtonItems = [b]
        self.title = "Group"

        listFiles()
        displayDataView.text = ""
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
        displayDataView.text = ""
        addData2()
    }
    
    @IBAction func openFileBtnPressed(_ sender: UIButton) {
        guard let name = openFileTxtField.text else {return}
        readData(from: name)
        view.endEditing(true)
        displayDataView.text = ""
    }

    @IBAction func addDataBtnPressed(_ sender: UIButton) {
        
        //MARK: check the name is not nil first, then activate alert view
        guard let firstName = self.firstNameTxtField.text else {return}
        guard let lastName = self.lastNameTxtField.text else {return}

        if firstName != "" || lastName != "" {
            self.firstNameTxtField.text = ""
            self.lastNameTxtField.text = ""
            addData(firstName: firstName, lastName: lastName)
        }
        else {
            //Missing data alert
            let av = UIAlertController(title: "Missing data", message: "Please enter a name", preferredStyle: .alert)
            av.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(av, animated: true, completion: nil)
        }

        displayDataView.text = ""
    }
    
    @IBAction func relaodDataBtnPressed(_ sender: UIButton) {
        guard let name = fileURL?.deletingPathExtension().lastPathComponent else {return}
        print("relaod file name: \(name)")
//        readData(from: name)
        addData3()
    }
    
    @IBAction func deleteFileBtnPressed(_ sender: UIButton) {
        createFile2()
    }
}

//MARK: - Business Logic
extension ViewController {
    
    //MARK: - 0 Listing file names
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
        
        statusBar.text = ""
        statusBar.text = " File list refreshed"
    }
    
    

    //MARK: - 1 Creating File.
    @objc func createFile(_: Any) {
        
        self.statusBar.text = ""    //clean status bar first
        
        //1 Create file name.
        let av = UIAlertController(title: "New File", message: "Enter name", preferredStyle: .alert)
        av.addTextField { (text) in
            text.autocapitalizationType = .words
        }
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        av.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            
            guard let name = av.textFields?[0].text, !name.isEmpty else {return}
            
            //2 Creating File URL.
            self.fileURL = self.docsURL.appendingPathComponent((name as NSString).appendingPathExtension("pplgrp")!)
            
            guard let fileURL = self.fileURL else { return }
            
            // really should check to see if file by this name exists
            if let _ = try? fileURL.checkResourceIsReachable() {

                //alerting file name duplicated
                let av = UIAlertController(title: "File Name Duplicated", message: "Please change the file name", preferredStyle: .alert)
                av.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(av, animated: true, completion: nil)
                
                self.statusBar.text = ""
                self.statusBar.text = " \(fileURL.lastPathComponent) file name duplicated."
            }
            else {
                //3 Init UIDocument with url.
                self.doc = PeopleDocument(fileURL: fileURL)
                
                //4 Saving data to document .forCreating
                self.doc!.save(to: self.doc!.fileURL, for: .forCreating, completionHandler: nil)
                
                self.statusBar.text = " Created document: \(fileURL.lastPathComponent)"
                self.files.append(self.fileURL!)    //Optional
            }
        }))
        
        self.present(av, animated: true)
        
//        self.listFiles()
        //Note: Archiving document will lead to time interal delay! So, you cann't scan out new created file as soon as saving the new file.
    }
    
    //MARK: - 2 Adding Data
    func createFile2() {
        //Create file
        fileURL = self.docsURL.appendingPathComponent("test.pplgrp")
        doc = PeopleDocument(fileURL: self.fileURL!)
        doc!.save(to: fileURL!, for: .forCreating, completionHandler: nil)
        
    }
    func addData2() {
        fileURL = self.docsURL.appendingPathComponent("test.pplgrp")
        doc = PeopleDocument(fileURL: self.fileURL!)
        doc?.open(completionHandler: { (success) in
            
            //Add data
            let newP = Person(firstName: "Test", lastName: "test!")
            self.people.append(newP)
            let newp2 = Person(firstName: "Test2", lastName: "test!")
            self.people.append(newp2)
            print(self.people.count)
            self.doc!.updateChangeCount(.done)
//            self.doc?.close(completionHandler: nil)
            print("people: \(self.doc!.people.count)")
        })
        
        //Read data
//        doc!.open(completionHandler: { (success) in
//            print(self.doc!.people.count)
//        })

    }
    func addData3() {
        fileURL = self.docsURL.appendingPathComponent("test.pplgrp")
        doc = PeopleDocument(fileURL: self.fileURL!)
        
        //Add data
//        let newP = Person(firstName: "Test3", lastName: "test!")
//        people.append(newP)
//        let newp2 = Person(firstName: "Test4", lastName: "test!")
//        people.append(newp2)
//        print(people.count)
//        self.doc!.updateChangeCount(.done)
//        print("people: \(doc!.people.count)")
        
        //Read data
        doc!.open(completionHandler: { (success) in
            print(self.doc!.people.count)
        })

    }

    func addData(firstName: String, lastName: String) {
            
        let av = UIAlertController(title: "File Name", message: "Please enter file name for adding data.", preferredStyle: .alert)
        av.addTextField(configurationHandler: {$0.autocapitalizationType = .words})
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        av.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            
            //1 creating file name
            guard let name = av.textFields?[0].text, !name.isEmpty else { return }
            
            //2 creating file url
            self.fileURL = self.docsURL.appendingPathComponent(name).appendingPathExtension("pplgrp")
            
            guard let fileURL = self.fileURL else { return }
            

            // really should check to see if file by this name exists
            if let _ = try? fileURL.checkResourceIsReachable() {
    
                //3 init uidocument with url.
                self.doc = PeopleDocument(fileURL: self.fileURL!)
                
                self.view.endEditing(true)  //dismiss keyboard

                //4 init Person object
                let newP = Person(firstName: firstName, lastName: lastName)
                
                //5 adding Person to People Model in UIDocument object
                self.people.append(newP)
                
                //6 updating data change
                self.doc!.updateChangeCount(.done)
                
                self.statusBar.text = " \"\(newP.firstName) \(newP.lastName)\" added into: \(fileURL.lastPathComponent)"
                
            }
            else {
                
                //alerting file name duplicated
                let av = UIAlertController(title: "File was not found", message: "Please create: \(fileURL.lastPathComponent) before adding data into it.", preferredStyle: .alert)
                av.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(av, animated: true, completion: nil)
                
                self.statusBar.text = ""
                self.statusBar.text = " \(fileURL.lastPathComponent) file name duplicated."
            }
            
        }))
        self.present(av, animated: true, completion: nil)
        
    }
    
    //MARK: 4 Reading data
    func readData(from name: String) {
        
        displayDataView.text = ""

        //1 creating file url
        self.fileURL = self.docsURL.appendingPathComponent(name).appendingPathExtension("pplgrp")
        
        guard let fileURL = self.fileURL else { return }
        
        // really should check to see if file by this name exists
        if let _ = try? fileURL.checkResourceIsReachable() {
            //2 Creating UIDocument
            let doc = PeopleDocument(fileURL: fileURL)
            
            //3 open document and load data.
            doc.open { (success) in
                //4 read data in document
                let people = doc.people
                for person in people {
                    print(person.firstName)
                    print(person.lastName)
                    
                    self.displayDataView.text += " \(person.firstName) \(person.lastName);"
                }
            }
            //4 close document.
//            doc.close(completionHandler: nil)
            
            self.statusBar.text = ""
            self.statusBar.text = " Read data from \(fileURL.lastPathComponent)"
            
            openFileTxtField.text = ""
        }
        else {
            //Missing file alert
            let av = UIAlertController(title: "Missing file", message: "Can't find \(fileURL.lastPathComponent).", preferredStyle: .alert)
            av.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(av, animated: true, completion: nil)
            
            self.statusBar.text = ""
            self.statusBar.text = " Can't find \(fileURL.lastPathComponent)"
        }
    }

    //MARK: - 5 Force Saving
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

//MARK: - Keyboard dismissing
extension ViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        view.endEditing(true)
    }
}

