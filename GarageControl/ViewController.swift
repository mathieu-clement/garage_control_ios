//
//  ViewController.swift
//  GarageControl
//
//  Created by Mathieu Clement on 10/4/15.
//  Copyright © 2015 Mathieu Clement. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    
    let garageControl = GarageControl()
    
    let WAIT_TIME:Float = 100 // * .25 seconds
    var timePassed:Float = 0 // seconds
    
    var timer = NSTimer()
    
    var geofence : Geofence!
    
    var isOpened = false
    
    let ALPHA_DISABLED = CGFloat(0.2)
    
    let laContext = LAContext()
    
    var uiIsVisible : Bool = false
    
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var doorStatusButton: UIButton!
    
    @IBOutlet weak var monitorLocationSwitch: UISwitch!
    
    @IBAction func buttonPressed(sender: UIButton) {
        if sender === openButton {
            handleCommand("open")
        } else if sender === closeButton {
            handleCommand("close")
        }
    }
    
    @IBAction func monitorLocationSwitchChanged() {
        if geofence == nil {
            geofence = Geofence(onEntering: self.whenApproachingGarage, onExiting: self.whenLeavingGarage)
        } else {
            geofence.stopMonitoring()
        }
        
        if monitorLocationSwitch.on {
            if geofence.isReadyForMonitoring() {
                var error : NSError?
                if laContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
                    laContext.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics,
                        localizedReason: "Ouvrir la porte en arrivant",
                        reply: { (success, error) -> Void in
                            if success {
                                self.geofence.startMonitoring()
                            } else {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.monitorLocationSwitch.on = false
                                })
                            }
                    })
                }
            }  else {
                monitorLocationSwitch.on = false
            }
        }
    }
    
    
    func launchProgress() {
        setProgressVisible(true)
        resetProgress()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.25,
            target: self, selector: Selector("onePeriodPassed"),
            userInfo: nil, repeats: true)
    }
    
    func setProgressVisible (visible:Bool) {
        statusLabel.hidden = !visible
        progressView.hidden = !visible
    }
    
    func resetProgress() {
        progressView.progress = 0
        timePassed = 0
        //statusLabel.text = "\(Int(WAIT_TIME)) s remaining..."
        statusLabel.text = ""
    }
    
    func onePeriodPassed() {
        timePassed++
        progressView.progress = timePassed/WAIT_TIME
        let timeRemaining = Int(WAIT_TIME-timePassed)
        //statusLabel.text = "\(timeRemaining) s remaining..."
        statusLabel.text = ""
        
        if (timeRemaining == 0) {
            timerExpired()
        }
    }
    
    func timerExpired() {
        timer.invalidate()
        setProgressVisible(false)
        resetProgress()
        enableButtons()
        
        refreshDoorStatus()
    }
    
    func disableButtons() {
        openButton.alpha = ALPHA_DISABLED
        closeButton.alpha = ALPHA_DISABLED
        openButton.enabled = false
        closeButton.enabled = false
    }
    
    func enableButtons() {
        openButton.alpha = isOpened ? ALPHA_DISABLED : 1.0
        closeButton.alpha = isOpened ? 1.0 : ALPHA_DISABLED
        openButton.enabled = true
        closeButton.enabled = true
    }
    
    func handleCommand(cmd: String) {
        self.disableButtons()
        self.progressView.tintColor = cmd == "open" ? UIColor.greenColor() : UIColor.redColor()
        
        var error : NSError?
        if laContext.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            laContext.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics,
                localizedReason: cmd == "open" ? "Ouvrir la porte" : "Fermer la porte",
                reply: { (success, error) -> Void in
                    if success {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.doHandleCommand(cmd, mustChangeUi: true)
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.enableButtons()
                        })
                    }
            })
        } else {
            self.enableButtons()
        }
    }
    
    func doHandleCommand(cmd:String, mustChangeUi:Bool) {
        if mustChangeUi {
            // Show text "Sending command..."
            statusLabel.text = "Transmission de la commande..."
            statusLabel.hidden = false
        }
        
        // HTTP Request
        garageControl.sendCmd(cmd,
            onSuccess: { () -> Void in
                if mustChangeUi {
                    self.statusLabel.hidden = true
                    self.statusLabel.text = ""
                    self.launchProgress()
                }
            },
            
            onFailure: { () -> Void in
                if mustChangeUi {
                    self.statusLabel.hidden = true
                    self.statusLabel.text = ""
                    self.enableButtons()
                }
        })
    }
    
    func displayNotification(title:String, _ body:String, sound:String? = nil) {
        let localNotification = UILocalNotification()
        localNotification.fireDate = NSDate(timeIntervalSinceNow: NSTimeInterval.init(1))
        localNotification.alertAction = title
        localNotification.alertBody = body
        localNotification.applicationIconBadgeNumber = 1
        if sound != nil {
            localNotification.soundName = sound
        } else {
            localNotification.soundName = UILocalNotificationDefaultSoundName
        }
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func whenApproachingGarage() {
        displayNotification("Garage Control", "Porte ouverte")
        stopMonitoring()
        self.doHandleCommand("open", mustChangeUi: uiIsVisible)
    }
    
    func whenLeavingGarage() {
        displayNotification("Garage Control", "Porte fermée")
        stopMonitoring()
        self.doHandleCommand("close", mustChangeUi: uiIsVisible)
    }
    
    func stopMonitoring() {
        if geofence != nil {
            geofence.stopMonitoring()
        }
        monitorLocationSwitch.on = false
    }
    
    @IBAction func doorStatusButtonTouched() {
        refreshDoorStatus()
    }
    
    func refreshDoorStatus() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.garageControl.askIfDoorOpened({
                (isOpened) -> Void in
                self.isOpened = isOpened
                self.doorStatusButton.setTitle(isOpened ? "Porte ouverte" : "Porte fermée", forState: .Normal)
                self.doorStatusButton.setTitleColor(isOpened ? UIColor.greenColor() : UIColor.redColor(), forState: .Normal)
                
                // Grey out button if it doesn't make sense due to the door status
                self.openButton.alpha = isOpened ? self.ALPHA_DISABLED : 1.0
                self.closeButton.alpha = isOpened ? 1.0 : self.ALPHA_DISABLED
                }) { () -> Void in
                    self.doorStatusButton.titleLabel!.text = "Statut de la porte : Erreur!"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setProgressVisible(false);
        statusLabel.text = ""
        
        laContext.touchIDAuthenticationAllowableReuseDuration = 0
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("appDidBecomeActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func appDidBecomeActive() {
        uiIsVisible = true
        refreshDoorStatus()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        timerExpired()
        uiIsVisible = false
    }
    
}

