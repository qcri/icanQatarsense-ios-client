//
//  HealthManager.swift
//  QatarSense
//
import HealthKit
import Foundation
import UIKit

public let stepCount: String = "stepCount"
public let activeCalories: String = "activeCalories"
public let heartRate: String = "heartRate"
public let distance: String = "distance"
public let flights: String = "flights"
public let valueSuffix: String = "_value"
public let dataKey:String = "jsonData"
public let lastSavedDate:String = "lastSavedDate"
public let deviceID:String = "deviceID"

struct HealthDataType {
  var dataPoint:HKQuantityType?
  var unit:HKUnit
  var key:String?
  var latestValue:Double?
  
  func handler(query:HKObserverQuery, completionHandler:HKObserverQueryCompletionHandler, error:NSError?) -> ()
  {
    if(key == "heartRate")
    {
      HealthManager().readRecentSample(self)
    }
    else
    {
      HealthManager().readTotal(self)
    }
  }
  
  mutating func setLatestValue(val:Double)
  {
    latestValue = val
  }
}

struct healthVars {
  static var healthDict : [String:HealthDataType] = [
    HKQuantityTypeIdentifierStepCount:HealthDataType(dataPoint: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount), unit:HKUnit.countUnit(),key:stepCount,latestValue:nil),
    HKQuantityTypeIdentifierActiveEnergyBurned:HealthDataType(dataPoint: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned)!, unit:HKUnit.kilocalorieUnit(),key:activeCalories,latestValue: nil),
    HKQuantityTypeIdentifierHeartRate:HealthDataType(dataPoint: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,unit:HKUnit(fromString: "count/min"),key:heartRate,latestValue:nil),
    HKQuantityTypeIdentifierDistanceWalkingRunning:HealthDataType(dataPoint: HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!, unit:HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Kilo),key:distance,latestValue:nil),
    HKQuantityTypeIdentifierFlightsClimbed:HealthDataType(dataPoint: HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierFlightsClimbed)!, unit: HKUnit.countUnit(),key:flights,latestValue:nil)
  ]
  
}

class HealthManager {
  
  static let healthManager = HealthManager()
  
  var stepViewController:StepsViewController?
  
  var isHealthAuthorized = false
  var isObservingChanges = false
  
  let defaults = NSUserDefaults.standardUserDefaults()
  
  //var jsonObject : [String:AnyObject] = [
   // "deviceID" : UIDevice.currentDevice().identifierForVendor!.UUIDString
  //]
  
  func generatePredicate(type:String) -> NSPredicate {
    let beginningOfToday = NSCalendar.currentCalendar().startOfDayForDate(NSDate())
    if let date = self.defaults.objectForKey(type) as! NSDate!
    {
      return NSPredicate.init(format: "startDate > %@", argumentArray: [date])
    }
    else {
      return HKQuery.predicateForSamplesWithStartDate(beginningOfToday,
        endDate: NSDate(), options: .StrictEndDate)
    }
  }
  
  func generateQuery(type:HealthDataType) -> HKObserverQuery {
    return HKObserverQuery(sampleType: type.dataPoint!,
      predicate: generatePredicate(type.key!),
      updateHandler: type.handler)
  }
  
  
  let healthKitStore:HKHealthStore = HKHealthStore()
  
  func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!)
  {
    // 1. Set the types you want to read from HK Store
    var healthKitTypesToRead : Set<HKObjectType> = [
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)!
    ]
    
    for healthKitType in healthVars.healthDict.values//healthKitTypes
    {
      healthKitTypesToRead.insert(healthKitType.dataPoint!)
    }
    
    // 2. If the store is not available (for instance, iPad) return an error and don't go on.
    if !HKHealthStore.isHealthDataAvailable()
    {
      let error = NSError(domain: "org.qcri.QatarSense", code: 2, userInfo: [NSLocalizedDescriptionKey:"Health Data not available in this Device"])
      if( completion != nil )
      {
        completion(success:false, error:error)
      }
      return;
    }
    
    // 3.  Request HealthKit authorization
    healthKitStore.requestAuthorizationToShareTypes(nil, readTypes: healthKitTypesToRead) { (success, error) -> Void in
      if( completion != nil )
      {
        if success && error == nil{
          self.isHealthAuthorized = true
          
          self.defaults.setObject(UIDevice.currentDevice().identifierForVendor!.UUIDString,forKey:deviceID)
          
          dispatch_async(dispatch_get_main_queue(),
            self.startObservingChanges)
        }
        
        completion(success:success,error:error)
      }
    }
  }
  
  var isAuthorized:Bool
    {
      return self.isHealthAuthorized
  }
  
  func setAuthorized()
  {
    self.isHealthAuthorized = true
  }
  
  func startObservingChanges()
  {    
    print("starting to observe changes")
    
    if isObservingChanges{
      return
    }
    for healthKitType in healthVars.healthDict.values
    {
      self.healthKitStore.executeQuery(generateQuery(healthKitType))
      self.healthKitStore.enableBackgroundDeliveryForType(healthKitType.dataPoint!,
        frequency: .Immediate,
        withCompletion: {succeeded, error in
          if succeeded{
            self.isObservingChanges = true
          } else {
            if let theError = error{
              print("Failed to enable background delivery of \(healthKitType.key) changes. ")
              print("Error = \(theError)")
            }
          }
      })
    }
  }
  
  /*
  deinit{
    stopObservingChanges()
  }
  
  func stopObservingChanges(){
  
    if isObservingChanges == false{
      return
    }
    for healthKitType in healthVars.healthDict.values//healthKitTypes
    {
      self.healthKitStore.stopQuery(generateQuery(healthKitType))
      healthKitStore.disableAllBackgroundDeliveryWithCompletion{
        succeeded, error in
        
        if succeeded{
          self.isObservingChanges = false
        } else {
          if let theError = error{
            print("Failed to disable background delivery of \(healthKitType.key) changes. ")
            print("Error = \(theError)")
          }
        }
      }
    }
  }*/
  
  func readTotal(var type:HealthDataType)
  {
    self.readTotalPerDay(type.dataPoint!, completion: { (sumQuantity, error) -> Void in
      
      if( error != nil )
      {
        print("Error reading data from HealthKit Store: \(error.localizedDescription)")
        return
      }
      
      let key = type.key! + valueSuffix
      
      let total = sumQuantity.doubleValueForUnit(type.unit)
      self.defaults.setObject(total,forKey:key)
      print("\(key) : \(total)")
      
      type.setLatestValue(total)

      if(UIApplication.sharedApplication().applicationState == UIApplicationState.Active)
      {
        self.defaults.synchronize()
        self.stepViewController?.updateInfo(type.key!)
      }
    })
    
    //save all new data to database
    self.saveData(type.dataPoint!, dataType: type.key!, unit: type.unit)
  }
  
  func readRecentSample(var type:HealthDataType)
  {
    print("getting latest sample")
    self.readMostRecentSample(type.dataPoint!, completion: { (mostRecentVal, error) -> Void in
      
      if( error != nil )
      {
        print("Error reading latest sample from HealthKit Store: \(error.localizedDescription)")
        return;
      }
      
      let qty = mostRecentVal as? HKQuantitySample;
      
      let lastVal = qty?.quantity.doubleValueForUnit(type.unit)
      
      let key = type.key! + valueSuffix
      print("\(key) : \(lastVal)")
      
      self.defaults.setObject(lastVal,forKey:key)
      
      //if(lastVal != nil)
      //{
        type.setLatestValue(lastVal!)
      //}
      
      if(UIApplication.sharedApplication().applicationState == UIApplicationState.Active)
      {
        self.defaults.synchronize()
        self.stepViewController?.updateInfo(type.key!)
      }
    })
    
    //save all new data to database
    self.saveData(type.dataPoint!, dataType: type.key!, unit: type.unit)
  }
  
  func readMostRecentSample(sampleType:HKSampleType , completion: ((HKSample!, NSError!) -> Void)!)
  {
    
    // 1. Build the Predicate
    let past = NSDate.distantPast()
    let now   = NSDate()
    let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
    
    // 2. Build the sort descriptor to return the samples in descending order
    let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
    // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
    let limit = 1
    
    // 4. Build samples query
    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
      { (sampleQuery, results, error ) -> Void in
        
        if let _ = error {
          completion(nil,error)
          return;
        }
        
        // Get the first sample
        let mostRecentSample = results!.first as? HKQuantitySample
        
        // Execute the completion closure
        if completion != nil {
          completion(mostRecentSample,nil)
        }
    }
    // 5. Execute the Query
    self.healthKitStore.executeQuery(sampleQuery)
  }
  
  func readTotalPerDay(sampleType:HKQuantityType, completion: ((HKQuantity, NSError!) -> Void)!)
  {
    // 1. Build the Predicate
    let start = NSCalendar.currentCalendar().startOfDayForDate(NSDate())
    let predicate = HKQuery.predicateForSamplesWithStartDate(start, endDate:NSDate(), options: .StrictStartDate)
    let sumOption = HKStatisticsOptions.CumulativeSum //| HKStatisticsOptions.SeparateBySource
    
    let query = HKStatisticsQuery(quantityType: sampleType, quantitySamplePredicate: predicate,
      options: sumOption)
      { (query, result, error) in
        if let sumQuantity = result?.sumQuantity() {
          completion(sumQuantity,error)
        }
        else {
          print("no data for \(sampleType)")
        }
    }
    
    // 5. Execute the Query
    self.healthKitStore.executeQuery(query)
  }
  
  
  func readRunningWorkOuts(workoutType:HKWorkoutActivityType,completion: (([AnyObject]!, NSError!) -> Void)!)
  {
    // 1. Build the Predicate
    let predicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(workoutType)//HKWorkoutActivityType.Running)
    
    // 2. Build the sort descriptor to return the samples in descending order
    let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
    
    // 3. Build samples query
    let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor])
      { (sampleQuery, results, error ) -> Void in
        
        if let queryError = error {
          print( "There was an error while reading the samples: \(queryError.localizedDescription)")
        }
        completion(results,error)
    }
    // 4. Execute the Query
    self.healthKitStore.executeQuery(sampleQuery)
    
  }
  
  //daily totals
  func dailyTotals(type:HKSampleType, completion: ([HKSample], NSError?) -> () )
  {
    
    // Our search predicate which will fetch data from beginning of day to now
    let endDate = NSDate()
    let startDate = NSCalendar.currentCalendar().startOfDayForDate(NSDate())
    
    let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
    
    // The actual HealthKit Query which will fetch all of the steps and sub them up for us.
    let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 0, sortDescriptors: nil) { query, results, error in
      completion(results!, error)
    }
    self.healthKitStore.executeQuery(query)
  }
  
  
  //send new data to the server
  /*func exportData(sampleType:HKQuantityType,dataType:String,unit:HKUnit)
  {
    //let stepType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
    let sortByTime = NSSortDescriptor(key:HKSampleSortIdentifierEndDate, ascending:true)
    let timeFormatter = NSDateFormatter()
    timeFormatter.dateFormat = "hh:mm:ss"
    
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "MM/dd/YYYY"
    
    var csvString = "Time,Date,Source,"+dataType+"\n"
    var predicate:NSPredicate? = nil
    
    if let date = self.defaults.objectForKey(dataType) as! NSDate!
    {
      print("\(dataType) saved date: \(date)")
      // predicate = HKQuery.predicateForSamplesWithStartDate(date, endDate: nil, options: .StrictStartDate)
      predicate = NSPredicate.init(format: "startDate > %@", argumentArray: [date])
    }
    
    let query = HKSampleQuery(sampleType:sampleType, predicate:predicate, limit:0, sortDescriptors:[sortByTime], resultsHandler:{(query, results, error) in
      guard let results = results else { return }
      for quantitySample in results {
        let quantity = (quantitySample as! HKQuantitySample).quantity
        //let heartRateUnit = HKUnit(fromString: "count/min")
        
        csvString += "\(timeFormatter.stringFromDate(quantitySample.startDate)),\(dateFormatter.stringFromDate(quantitySample.startDate)),\(quantitySample/*.sourceRevision*/.source.bundleIdentifier),\(quantity.doubleValueForUnit(unit))\n"
        //print("\(timeFormatter.stringFromDate(quantitySample.startDate)),\(dateFormatter.stringFromDate(quantitySample.startDate)),\(quantity.doubleValueForUnit(HKUnit.countUnit()))\n")
      }
      
      if results.count >= 1
      {
        let quantitySample = results[results.count - 1]
        self.defaults.setObject(quantitySample.startDate, forKey: dataType)
        //print(quantitySample.startDate)
        
      let URL: NSURL = NSURL(string: "http://scdev5.qcri.org/healthSystem/getAppData.jsp")!
        //"http://192.168.1.140:8080/healthSystem/getAppleData.jsp")!
      let request:NSMutableURLRequest = NSMutableURLRequest(URL:URL)
      request.HTTPMethod = "POST"
      let bodyData = "dataType="+dataType+"&data="+csvString
      request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding);
      //NSURLSession.sharedSession().dataTaskWithRequest(request)
      NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
        (response, data, error) in
        if(error != nil)
        {
          //print(NSString(data: data!, encoding: NSUTF8StringEncoding))
          print(error)
        }
      }
      }
      
    })
    self.healthKitStore.executeQuery(query)
  }*/
  
  //save data to be sent to the server
  func saveData(sampleType:HKQuantityType,dataType:String,unit:HKUnit)
  {
    //let stepType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
    let sortByTime = NSSortDescriptor(key:HKSampleSortIdentifierEndDate, ascending:false)
    //let timeFormatter = NSDateFormatter()
    //timeFormatter.dateFormat = "hh:mm:ss"
    
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "MM/dd/YYYY hh:mm:ss"
    
    var data: [AnyObject] = []// = "Time,Date,Source,"+dataType+"\n"
    var predicate:NSPredicate? = nil
    
    if let date = self.defaults.objectForKey(dataType) as! NSDate!
    {
      //print("\(dataType) saved date: \(date)")
      // predicate = HKQuery.predicateForSamplesWithStartDate(date, endDate: nil, options: .StrictStartDate)
      predicate = NSPredicate.init(format: "startDate > %@", argumentArray: [date])
    }
    
    let query = HKSampleQuery(sampleType:sampleType, predicate:predicate, limit:0, sortDescriptors:[sortByTime], resultsHandler:{(query, results, error) in
      guard let results = results else { return }
      for quantitySample in results {
        let quantity = (quantitySample as! HKQuantitySample).quantity
        
        data.append(["start time":dateFormatter.stringFromDate(quantitySample.startDate),"end time":dateFormatter.stringFromDate(quantitySample.endDate),"source":quantitySample.source.bundleIdentifier,"dataType":dataType,"value":quantity.doubleValueForUnit(unit)])
      }
      
      if results.count >= 1
      {
        let quantitySample = results[0]
        self.defaults.setObject(quantitySample.startDate, forKey: dataType)
        
        if let prevData = self.defaults.objectForKey(dataKey) as![AnyObject]!
        {
          data.appendContentsOf(prevData)
        }
        self.defaults.setObject(data, forKey: dataKey)
        /*if let lastDate = self.defaults.objectForKey(lastSavedDate) as! NSDate? {
          if(NSCalendar.currentCalendar().components(NSCalendarUnit.Minute, fromDate: lastDate, toDate: NSDate(), options: []).minute > 10)
          {
            print("time exceed send to server \(lastDate) \(NSCalendar.currentCalendar().components(NSCalendarUnit.Minute, fromDate: lastDate, toDate: NSDate(), options: []).minute)")
            self.sendDataToServer()
          }
        }*/
      }
      
    })
    self.healthKitStore.executeQuery(query)
  }
  
  //send new data to the server
  func sendDataToServer()
  {
    if let lastDate = self.defaults.objectForKey(lastSavedDate) as! NSDate? {
      let interval:Int = NSCalendar.currentCalendar().components(NSCalendarUnit.Second, fromDate: lastDate, toDate: NSDate(), options: []).minute
      if(interval > 10)
      {
        print("time exceed send to server \(lastDate) \(interval)")
        if let jsonData = self.defaults.objectForKey(dataKey) as! [AnyObject]!
        {
          if(jsonData.count > 0)
          {
            print(jsonData.count)
          var jsonObject:[String:AnyObject] = [deviceID:self.defaults.objectForKey(deviceID)!]//["jsondata":jsonData]
          jsonObject[dataKey] = jsonData
          if NSJSONSerialization.isValidJSONObject(jsonObject) {
            do
            {
              let data = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions(rawValue: 0))
              let bodyData = "data=" + String(data: data, encoding: NSUTF8StringEncoding)!
              let URL: NSURL = NSURL(string: "http://scdev5.qcri.org/healthSystem/getAppData.jsp")!
              let request:NSMutableURLRequest = NSMutableURLRequest(URL:URL)
              request.HTTPMethod = "POST"
              print(bodyData)
              request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding);
              request.addValue("application/x-www-form-urlencoded",forHTTPHeaderField:"Content-Type")
              request.addValue("application/json",forHTTPHeaderField: "Accept")
              
              //
              let session:NSURLSession = NSURLSession.sharedSession()
              let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                //NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                //(response, data, error) in
                if(error != nil)
                {
                  //print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                  print(error)
                }
                else
                {
                  //var data: [AnyObject] = []
                  self.defaults.setObject([], forKey: dataKey)
                  self.defaults.setObject(NSDate(), forKey: lastSavedDate)
                }
              })
              
              task.resume()
            }
            catch{
              print("error serializing json data")
            }
          }
          else
          {
            print("invalid json data")
          }
        }
        }
      }
    }
  }

  
  func readProfile() -> ( age:Int?,  biologicalsex:HKBiologicalSexObject?)//, bloodtype:HKBloodTypeObject?)
  {
    //var error:NSError?
    var age:Int?
    var biologicalSex:HKBiologicalSexObject?
    //var bloodType:HKBloodTypeObject?
    
    // 1. Request birthday and calculate age
    do{
      let birthDay = try healthKitStore.dateOfBirth()
      let today = NSDate()
      //let calendar = NSCalendar.currentCalendar()
      let differenceComponents = NSCalendar.currentCalendar().components(.Year, fromDate: birthDay, toDate: today, options: NSCalendarOptions(rawValue: 0) )
      age = differenceComponents.year
    }
    catch {
      print("Error reading Birthday")
    }
    
    // 2. Read biological sex
    do {
      biologicalSex = try healthKitStore.biologicalSex();
    }
    catch {
      print("Error reading Biological Sex")
    }
    // 3. Read blood type
    /*do
    {
      bloodType = try healthKitStore.bloodType();
      print(bloodType)
    }
    catch {
      print("Error reading Blood Type")
    }*/

    // 4. Return the information read in a tuple
    return (age, biologicalSex)//, bloodType)
  }
  
}