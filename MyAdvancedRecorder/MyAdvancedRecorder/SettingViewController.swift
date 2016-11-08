//
//  SettingViewController.swift
//  MyAdvancedRecorder
//
//  Created by Linsw on 15/12/29.
//  Copyright © 2015年 Linsw. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
class SettingViewController: UIViewController {

    @IBOutlet weak var bitRateSegment: UISegmentedControl!

    var settingObject:NSManagedObject?
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if settingObject != nil{
            updateSettingParameter(settingObject!,bitRateSegmentIndex: bitRateSegment.selectedSegmentIndex)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
    func initView(){
        settingObject = fetchSettingObject()
        if settingObject != nil{
            let bitRate = Int(settingObject?.value(forKey: "bitRateKey") as!Int)
            bitRateSegment.selectedSegmentIndex = setBitRateSegmentIndex(bitRate)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
/*
    func transformQualityValue(segmentIndex:Int)->Int{
        switch segmentIndex{
        case 0: return 0
        case 1: return 0x20
        case 2: return 0x40
        case 3: return 0x60
        case 4: return 0x7F
        default: return 0x40
        }
    }
    func transformSampleRate(segmentIndex:Int)->Float{
        switch segmentIndex{
        case 0: return 8000.0
        case 1: return 11025.0
        case 2: return 22050.0
        case 3: return 32000.0
        case 4: return 44100.0
        default: return 44100.0
        }
    }*/
    func transformBitRate(_ segmentIndex:Int)->Int{
        switch segmentIndex{
        case 0:return 128_000
        case 1:return 160_000
        case 2:return 192_000
        case 3:return 320_000
        default:return 320_000
        }
    }
    func setBitRateSegmentIndex(_ bitRate:Int)->Int{
        switch bitRate{
        case 128_000:return 0
        case 160_000:return 1
        case 192_000:return 2
        case 320_000:return 3
        default:return 3
        }
    }
    func updateSettingParameter(_ managedObject:NSManagedObject,bitRateSegmentIndex:Int){
        let bitRate = transformBitRate(bitRateSegmentIndex)
        managedObject.setValue(NSNumber(value: kAudioFormatMPEG4AAC as UInt32), forKey: "formatIDKey")
        managedObject.setValue(AVAudioQuality.medium.rawValue, forKey: "qualityKey")
        managedObject.setValue(2, forKey: "numberOfChannelsKey")
        managedObject.setValue(bitRate, forKey: "bitRateKey")
        managedObject.setValue(44100.0, forKey: "sampleRateKey")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        do {
            try managedContext.save()
        }catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    func fetchSettingObject()->NSManagedObject{
        var object=[NSManagedObject]()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SettingParameter")
        do {
            object = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return object[0]
    }
}
