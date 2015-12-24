//
//  FileListTableViewController.swift
//  MyAdvancedRecorder
//
//  Created by Linsw on 15/12/22.
//  Copyright © 2015年 Linsw. All rights reserved.
//

import UIKit
import CoreData
class FileListTableViewController: UITableViewController {
    let appFilePath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
    var myRecordFileURL = [NSManagedObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        //set backgroundcolor of tableview
        tableView.backgroundView = UIView.init()
        tableView.backgroundView?.backgroundColor = UIColor.grayColor()
            // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // 从coredata中获取数据
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        //2
        let fetchRequest = NSFetchRequest(entityName: "MyRecordFile")
        //3
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            myRecordFileURL = results as! [NSManagedObject]
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        tableView.reloadData()
        
        let tempManager = NSFileManager.defaultManager()
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        do{
            let pathString = try tempManager.contentsOfDirectoryAtPath(path)
            NSLog("\(pathString),")
            
        }catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return myRecordFileURL.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell", forIndexPath: indexPath) as! FileListTableViewCell

        // Configure the cell...
        
        let recordFileURL = myRecordFileURL[indexPath.row]
        cell.fileNameLabel.text = recordFileURL.valueForKey("saveDate")?.description
        NSLog("\(cell.fileNameLabel.text)")
        return cell
    }
    

   
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            let fileManager = NSFileManager.defaultManager()
            let path = appFilePath + myRecordFileURL[indexPath.row].valueForKey("fileName")!.description
            do{
                try fileManager.removeItemAtPath(path)

            }catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
            
//            从数据库中删除该项
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            managedContext.deleteObject(myRecordFileURL[indexPath.row])
            NSLog("\(indexPath.row)")
            do {
//                保存删除的结果（使删除生效）
                try managedContext.save()
                
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
            
//            再从数组中移除数据
            myRecordFileURL.removeAtIndex(indexPath.row)
            
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.reloadData()  
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
    }
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "playRecord" {
            // self.tableView.reloadData()
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = segue.destinationViewController as! PlayerViewController
                let path = myRecordFileURL[indexPath.row]
//               将文件路径传递到playerview里
                let stringPath = appFilePath + (path.valueForKey("fileName")?.description)!
                controller.playPath = stringPath
//                self.tableView.reloadData()
//                controller.myTextView.text = stringPath
            }
        }
    }

}
