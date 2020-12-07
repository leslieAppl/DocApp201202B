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
    @IBOutlet weak var renameAndRemoveFileTxtField: UITextField!
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
    }
    
    @IBAction func ReadDataBtnPressed(_ sender: UIButton) {
        view.endEditing(true)

        guard let name = openFileTxtField.text else {return}
        readData(from: name)
    }

    @IBAction func addDataBtnPressed(_ sender: UIButton) {
        
        self.view.endEditing(true)  //dismiss keyboard
        displayDataView.text = ""
        
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
        displayDataView.text = ""
        guard let name = fileURL?.deletingPathExtension().lastPathComponent else {return}
        print("relaod file name: \(name)")
        readData(from: name)
    }
    
    @IBAction func renameFileBtnPressed(_ sender: UIButton) {
        displayDataView.text = ""

        guard let name = renameAndRemoveFileTxtField.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {return}
        renameFile(from: name)
    }
    
    @IBAction func removeFileBtnPressed(_ sender: UIButton) {
        displayDataView.text = ""
        
        guard let name = renameAndRemoveFileTxtField.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {return}
        removeFile(from: name)
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
        self.displayDataView.text = ""
        
        let av = UIAlertController(title: "New File", message: "Enter name", preferredStyle: .alert)
        av.addTextField { (text) in
            text.autocapitalizationType = .words
        }
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        av.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            
            guard let name = av.textFields?[0].text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {return}
            
            //1 Creating File URL.
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
                //2 Init UIDocument with url.
                self.doc = PeopleDocument(fileURL: fileURL)
                
                //3 Saving data to document .forCreating
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
    func addData(firstName: String, lastName: String) {
        
        let av = UIAlertController(title: "File Name", message: "Please enter file name for adding data.", preferredStyle: .alert)
        av.addTextField(configurationHandler: {$0.autocapitalizationType = .words})
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        av.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            
            guard let name = av.textFields?[0].text, !name.isEmpty else {
                
                // missing file name alert
                let av = UIAlertController(title: "File was not found", message: "Please create: \(self.fileURL!.lastPathComponent) before adding data into it.", preferredStyle: .alert)
                av.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(av, animated: true, completion: nil)
                
                self.statusBar.text = ""
                self.statusBar.text = " \(self.fileURL!.lastPathComponent) file name duplicated."
                
                return
            }
            
            do {
                
                //1 creating file url
                self.fileURL = self.docsURL.appendingPathComponent(name).appendingPathExtension("pplgrp")
                
                guard let fileURL = self.fileURL else { return }
                                
                // really should check to see if file by this name exists
                if try fileURL.checkResourceIsReachable() {
                    
                    //2 init uidocument with url
                    self.doc = PeopleDocument(fileURL: self.fileURL!)
                    
                    //3 open document and load data.
                    self.doc?.open(completionHandler: { (success) in
                        
                        //MARK: - Adding data task
                        //4 init Person object
                        let newP = Person(firstName: firstName, lastName: lastName)
                        
                        //5 adding Person to People Model
                        self.people.append(newP)
                        
                        //6 updating data change
                        self.doc!.updateChangeCount(.done)
                        
                        self.statusBar.text = " \"\(newP.firstName) \(newP.lastName)\" added into: \(fileURL.lastPathComponent)"
                        
                        //MARK: - Reading data task
                        self.displayDataView.text = ""
                        
                        let people = self.doc!.people
                        print("Testing: \(people)")
                        for person in people {
                            self.displayDataView.text += " \(person.firstName) \(person.lastName);"
                        }
                    })
                    
                    //7 close document
                    self.doc?.close(completionHandler: nil)
                    
                }
                else {
                    
                    //alerting file name duplicated
                    let av = UIAlertController(title: "File was not found", message: "Please create: \(fileURL.lastPathComponent) before adding data into it.", preferredStyle: .alert)
                    av.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(av, animated: true, completion: nil)
                    
                    self.statusBar.text = ""
                    self.statusBar.text = " \(fileURL.lastPathComponent) file name duplicated."
                }
            } catch {
                print(error)
            }
            
        }))
        self.present(av, animated: true, completion: nil)
        
    }

    //MARK: 3 Reading data
    func readData(from name: String) {

        //1 creating file url
        self.fileURL = self.docsURL.appendingPathComponent(name.trimmingCharacters(in: .whitespaces)).appendingPathExtension("pplgrp")
        
        guard let fileURL = self.fileURL else { return }
        
        // really should check to see if file by this name exists
        if let _ = try? fileURL.checkResourceIsReachable() {
            //2 Init UIDocument with url
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
            doc.close(completionHandler: nil)
            
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
    
    //MARK: - 4 Renaming File
    func renameFile(from oldName: String) {
        
        let av = UIAlertController(title: "New File", message: "Enter name", preferredStyle: .alert)
        av.addTextField { (text) in
            text.autocapitalizationType = .words
        }
        av.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        av.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            guard let newName = av.textFields?[0].text?.trimmingCharacters(in: .whitespaces), !newName.isEmpty else {return}
            
            //1 Creating File URL.
            let newFileName = self.docsURL.appendingPathComponent((newName as NSString).appendingPathExtension("pplgrp")!)
            let oldFileName = self.docsURL.appendingPathComponent(oldName).appendingPathExtension("pplgrp")
            
        do {
            
            //2 removing file
            try FileManager.default.moveItem(at: oldFileName, to: newFileName)
            self.statusBar.text = " Renamed \(oldFileName.lastPathComponent) to \(newFileName.lastPathComponent)."
            
        } catch {
            print(error)
        }

        }))
        
        self.present(av, animated: true, completion: nil)
    }
        

    
    //MARK: - 5 Removing File
    func removeFile(from name: String) {
        
        do {
            
            //1 url
            self.fileURL = self.docsURL.appendingPathComponent(name).appendingPathExtension("pplgrp")

            //2 removing file
            try FileManager.default.removeItem(at: fileURL!)
            self.statusBar.text = " \(String(describing: fileURL!.lastPathComponent)) has been removed."
            
        } catch {
            print(error)
        }
    }

    //MARK: - 6 Force Saving
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

