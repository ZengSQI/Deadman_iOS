//
//  ViewController.swift
//  Deadman_iOS
//
//  Created by Steven Zeng on 2018/6/6.
//  Copyright © 2018年 REDEV. All rights reserved.
//

import UIKit
import PlainPing

struct IPModel {
    var ip:String
    var name:String
    
    init(ip:String, name:String) {
        self.ip = ip
        self.name = name
    }
    
    init?(dictionary : [String:String]) {
        guard let ip = dictionary["ip"],
            let name = dictionary["name"] else { return nil }
        self.init(ip: ip, name: name)
    }
    
    var propertyListRepresentation : [String:String] {
        return ["ip" : ip, "name" : name]
    }
    
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var pings:[IPModel] = []
    
    let ud:UserDefaults = UserDefaults.standard
    
    var pingsAtRun:[IPModel] = []
    
    var currentUpateindex:Int = 0
    
    var results:[String:Double] = [:]
    
    var running:Bool = false
    var editingtable:Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var new: UIBarButtonItem!
    @IBOutlet weak var edit: UIBarButtonItem!
    @IBOutlet weak var run: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.register(UINib(nibName: "IPTableViewCell", bundle: nil), forCellReuseIdentifier: "IPCell")
        
        tableView.allowsSelection = false
        tableView.allowsSelectionDuringEditing = true

        if let propertylistPings = ud.object(forKey: "pings") as? [[String:String]] {
            pings = propertylistPings.compactMap{ IPModel(dictionary: $0) }
        }else{
            ud.set([["name":"GOOGLE_DNS", "ip":"8.8.8.8"], ["name":"CHT_DNS", "ip":"168.95.1.1"]], forKey: "pings")
            pings = [IPModel(ip: "8.8.8.8", name: "GOOGLE_DNS"),
                     IPModel(ip: "168.95.1.1", name: "CHT_DNS")]
        }
        
        for ping in pings{
            results[ping.ip] = 0.0
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IPCell") as! IPTableViewCell
        
        let ping = pings[indexPath.row]
        
        if ping.name == "" {
            cell.name.text = ping.ip
            cell.IP.text = ""
        }else{
            cell.name.text = ping.name
            cell.IP.text = ping.ip
        }
        
        if currentUpateindex == indexPath.row && running == true{
            cell.indicator.isHidden = false
        }else{
            cell.indicator.isHidden = true
        }
        
        if let result = results[ping.ip] {
            if running == false{
                cell.result.textColor = UIColor.lightGray
            }else if result > 500.0{
                cell.result.textColor = UIColor.red
            }else if result > 200.0{
                cell.result.textColor = UIColor.orange
            }else if result > 70.0{
                cell.result.textColor = UIColor.yellow
            }else{
                cell.result.textColor = UIColor.green
            }
            
            cell.result.text = "\(String(format: "%.2f", results[ping.ip]!)) ms"
        }else{
            cell.result.textColor = UIColor.red
            cell.result.text = "error"
        }
        
        return cell
    }
    
    
    @IBAction func run(_ sender: UIBarButtonItem) {
        if running == false{
            sender.title = "Stop"
            new.isEnabled = false
            edit.isEnabled = false
            running = true
        }else{
            sender.title = "Run"
            new.isEnabled = true
            edit.isEnabled = true
            running = false
        }
        
        pingsAtRun = pings
        pingNext(0)
    }
    
    func pingNext(_ index:Int) {
        currentUpateindex = index
        
        guard pingsAtRun.count > 0 else {
            if running == true{
                pingsAtRun = pings
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.pingNext(0)
                }
            }else{
                self.tableView.reloadData()
            }
            return
        }
        if index != 0{
            
        }
        let ping = pingsAtRun.removeFirst()
        PlainPing.ping(ping.ip, withTimeout: 1.0, completionBlock: { (timeElapsed:Double?, error:Error?) in
            if let latency = timeElapsed {
                print("\(ping.name) latency (ms): \(latency)")
                self.results[ping.ip] = latency
                self.tableView.reloadData()
            }
            if let error = error {
                print("error: \(error.localizedDescription)")
                self.results[ping.ip] = 999.99
                self.tableView.reloadData()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
                self.pingNext(index+1)
            }
        })
    }
    
    
    @IBAction func newPing(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "新增",
            message: nil,
            preferredStyle: .alert)
        
        
        let okAction = UIAlertAction(
            title: "確定",
            style: .default,
            handler: {
                (action: UIAlertAction!) -> Void in
                let ip =
                    (alertController.textFields?.first)! as UITextField
                let name =
                    (alertController.textFields?.last)! as UITextField
                
                print("ip    = \(ip.text!)")
                print("name = \(name.text!)")
                self.pings.append(IPModel(ip: ip.text!, name: name.text!))
                self.results[ip.text!] = 0.0
                
                self.updateUD()
                self.tableView.reloadData()
        }
            
        )
        
        
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(
            title: "取消",
            style: .cancel,
            handler: nil)
        
        alertController.addAction(cancelAction)
        
        
        //兩個輸入欄位
        alertController.addTextField {
            (textField: UITextField!) -> Void in
            textField.placeholder = "IP"
        }
        
        alertController.addTextField {
            (textField: UITextField!) -> Void in
            textField.placeholder = "Name"
        }
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion:nil )
        }

    }
    
    @IBAction func editPing(_ sender: UIBarButtonItem) {
        if editingtable == false{
            editingtable = true
            sender.title = "Done"
            self.new.isEnabled = false
            self.run.isEnabled = false
            self.tableView.setEditing(true, animated: true)
        }else{
            editingtable = false
            sender.title = "Edit"
            self.new.isEnabled = true
            self.run.isEnabled = true
            self.tableView.setEditing(false, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            results.removeValue(forKey: pings[indexPath.row].ip)
            pings.remove(at: indexPath.row)
            self.updateUD()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            break
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(
            title: "編輯",
            message: nil,
            preferredStyle: .alert)
        
        
        let okAction = UIAlertAction(
            title: "確定",
            style: .default,
            handler: {
                (action: UIAlertAction!) -> Void in
                let ip =
                    (alertController.textFields?.first)! as UITextField
                let name =
                    (alertController.textFields?.last)! as UITextField
                
                print("ip    = \(ip.text!)")
                print("name = \(name.text!)")
                self.pings[indexPath.row] = IPModel(ip: ip.text!, name: name.text!)
                self.results[ip.text!] = 0.0
                self.updateUD()
                self.tableView.reloadData()
        }
            
        )
        
        
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(
            title: "取消",
            style: .cancel,
            handler: nil)
        
        alertController.addAction(cancelAction)
        
        
        alertController.addTextField {
            (textField: UITextField!) -> Void in
            textField.placeholder = "IP"
            textField.text = self.pings[indexPath.row].ip
        }
        
        alertController.addTextField {
            (textField: UITextField!) -> Void in
            textField.placeholder = "Name"
            textField.text = self.pings[indexPath.row].name
        }
        
        // 顯示提示框
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion:nil )
        }
    }
    
    func updateUD(){
        let propertylistPings = pings.map{ $0.propertyListRepresentation }
        ud.set(propertylistPings, forKey: "pings")
    }
}

