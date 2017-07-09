//
//  MasterViewController.swift
//  QatarSense
//

import Foundation

import UIKit


class MasterViewController: UITableViewController {
  
  let kAuthorizeHealthKitSection = 2
  let kProfileSegueIdentifier = "profileSegue"
  let kVitalsSegueIdentifier = "vitalsSegue"
  
  //let healthManager:HealthManager = HealthManager()
  
  func authorizeHealthKit()
  {
    print("going to authorize")
    HealthManager.healthManager.authorizeHealthKit { (authorized,  error) -> Void in
      if authorized {
        print("HealthKit authorization received.")
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
  
  
  // MARK: - Segues
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    /*if(healthManager.isAuthorized) {
      dispatch_async(dispatch_get_main_queue(),healthManager.startObservingChanges)
    }*/
    
    /*if segue.identifier ==  kProfileSegueIdentifier {
      
      if let profileViewController = segue.destinationViewController as? ProfileViewController {
        profileViewController.healthManager = healthManager
      }
    }
    else if segue.identifier == kVitalsSegueIdentifier {
      if let vitalsViewController = segue.destinationViewController as? StepsViewController {
        vitalsViewController.healthManager = healthManager;
      }
    }*/
  }
  
  // MARK: - TableView Delegate
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    switch (indexPath.section, indexPath.row)
    {
    case (kAuthorizeHealthKitSection,0):
      authorizeHealthKit()
    default:
      break
    }
    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    if(!HealthManager.healthManager.isAuthorized)
    {
      authorizeHealthKit()
    }
  }

  
  
  
}
