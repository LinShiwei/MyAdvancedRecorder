//
//  RecordPalTests.swift
//  RecordPalTests
//
//  Created by Linsw on 16/3/10.
//  Copyright © 2016年 Linsw. All rights reserved.
//

import XCTest
@testable import RecordPal
//@testable import MyAdvancedRecorder
class RecordPalTests: XCTestCase {
    
    var viewController :RecorderViewController!
    var navigationController: UINavigationController!
    override func setUp() {
        super.setUp()
        navigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
        viewController = navigationController.topViewController as! RecorderViewController
        let _ = viewController.view

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        let managedContext = viewController.getManagedContext()
        for object in viewController.myRecordFile {
            managedContext.delete(object)
        }
        do {
            try managedContext.save()
        }
        catch {
        }
        super.tearDown()
    }
    
    func testCreateNewRecordURL() {
        viewController.addNewRecordFileObjectToMyRecordFile()
        let url = viewController.getNewRecordURL()
        XCTAssertNotNil(url)
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    func testAddNewRecordFileObject(){
        let preCount = viewController.myRecordFile.count
        viewController.addNewRecordFileObjectToMyRecordFile()
        XCTAssertEqual(preCount, viewController.myRecordFile.count - 1 )
    }
    func testRecordAndPlay(){
        
        viewController.startRecord()
        XCTAssertTrue(viewController.recorder!.isRecording)
        viewController.stopRecord()
        XCTAssertNil(viewController.recorder)
        
        viewController.startPlay()
        XCTAssertTrue(viewController.player!.isPlaying)
        viewController.stopPlay()
        XCTAssertFalse(viewController.player!.isPlaying)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
}
