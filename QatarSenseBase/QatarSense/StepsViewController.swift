//
//  StepsViewController.swift
//  QatarSense
//

import UIKit
import HealthKit
import Foundation

class StepsViewController: UITableViewController {
  
  let UpdateFitnessInfoSection = 2
  let kUnknownString   = "Unknown"

  
  @IBOutlet var stepsLabel:UILabel!
  @IBOutlet var distanceLabel:UILabel!
  @IBOutlet var flightsLabel:UILabel!
  @IBOutlet var heartRateLabel:UILabel!
  @IBOutlet var caloriesLabel:UILabel!
  
  var hr, steps, dist:HKQuantitySample?
  
  //var healthManager:HealthManager?
  
  func authorizeHealthKit()
  {
    print("going to authorize in StepViewController")
    HealthManager.healthManager.authorizeHealthKit { (authorized,  error) -> Void in
      if authorized {
        self.updateHealthInfo();
      }
      else
      {
        print("HealthKit authorization denied!")
        if error != nil {
          print("\(error)")
        }
      }
    }
  }
  
  func updateHealthInfo() {
    
    print(UIDevice.currentDevice().name)//.identifierForVendor!.UUIDString)
  
    updateSteps();
    updateDistance();
    updateFlights();
    updateCalories();
    updateHeartRate();
  }
  
  func updateInfo(key:String)
  {
    /*if(key == stepCount)
    {
      updateSteps()
    }
    else if(key == activeCalories)
    {
      updateCalories()
    }*/
    print(key)
    
    switch(key)
    {
    case stepCount:
      updateSteps()
      break
    case activeCalories:
      updateCalories()
      break
    case distance:
      updateDistance()
      break
    case flights:
      updateFlights()
      break
    case heartRate:
      updateHeartRate()
      break
    default:
      break
    }
  }
  
  func updateSteps() {
    
    if let steps = NSUserDefaults.standardUserDefaults().objectForKey(stepCount + valueSuffix) as! Int! {
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.stepsLabel.text = "\(steps)"
      });
    }
    else
    {
      print("no step data found")
      HealthManager.healthManager.readTotal((healthVars.healthDict[HKQuantityTypeIdentifierStepCount])!)
    }
  }
  
  func updateDistance()
  {
    
    var distanceString = self.kUnknownString;
    
    if let distance = NSUserDefaults.standardUserDefaults().objectForKey(distance + valueSuffix) as! Double! {
      distanceString = NSLengthFormatter().stringFromValue(distance, unit: NSLengthFormatterUnit.Kilometer)
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.distanceLabel.text = distanceString
      });
    }
    else
    {
      print("no distance data found")
      HealthManager.healthManager.readTotal((healthVars.healthDict[HKQuantityTypeIdentifierDistanceWalkingRunning])!)
    }
    
  }
  
  func updateFlights()
  {
    if let flights = NSUserDefaults.standardUserDefaults().objectForKey(flights + valueSuffix) as! Int! {
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.flightsLabel.text = "\(flights)"
      });
    }
    else
    {
      print("no flight data found")
      HealthManager.healthManager.readTotal((healthVars.healthDict[HKQuantityTypeIdentifierFlightsClimbed])!)
    }
  }
  
  func updateCalories()
  {
     var caloriesString = self.kUnknownString;
    
    if let calories = NSUserDefaults.standardUserDefaults().objectForKey(activeCalories + valueSuffix) as! Double! {
      caloriesString = NSEnergyFormatter().stringFromValue(calories, unit: .Kilocalorie)
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.caloriesLabel.text = caloriesString
      });
    }
    else
    {
      print("no calorie data found")
      HealthManager.healthManager.readTotal((healthVars.healthDict[HKQuantityTypeIdentifierActiveEnergyBurned])!)
    }
  }
  
  
  func updateHeartRate()
  {
    var hrLocalizedString = self.kUnknownString;
    
    if let hr = NSUserDefaults.standardUserDefaults().objectForKey("heartRate_value") as! Int! {
      hrLocalizedString = NSNumberFormatter().stringFromNumber(hr)!
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.heartRateLabel.text = hrLocalizedString
      });
    }
    else
    {
      print("no heart data found")
      HealthManager.healthManager.readRecentSample((healthVars.healthDict[HKQuantityTypeIdentifierHeartRate])!)
    }

  }

  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    switch (indexPath.section, indexPath.row)
    {
    case (UpdateFitnessInfoSection,0):
      updateHealthInfo()
    default:
      break
    }
    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    if(HealthManager.healthManager.isAuthorized == true)
    {
      updateHealthInfo()
    }
    else
    {
      authorizeHealthKit()
    }
  }
}

