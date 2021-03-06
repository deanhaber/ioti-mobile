//
//  Utils.swift
//  IoT4I
//
//  Created by Amjad Nashashibi on 10/06/2016.
//
//  Copyright (c) IBM Corporation 2016. All rights reserved.
//
//  Material provided under the MIT license; intended solely for use with an
//  Apple iOS product and intended to be used in conjunction with officially
//  licensed Apple development tools and further customized and distributed
//  under the terms and conditions of your licensed Apple developer program.
//
//  The MIT License (MIT)
//
//  Copyright (c) IBM Corporation 2016. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


import UIKit
import AVFoundation
import CoreData
import CocoaLumberjack
import UICKeyChainStore

class Utils {
    static var sharedInstance = Utils()
    
}


extension Utils {
    
    class func addHazardEvent(hzrdEvntDic :[String:AnyObject], hazardTitle:String)
    {
        
        let moc = dataController.writerContext
        
        guard let shieldUUID = hzrdEvntDic["shieldUUID"] as? String else {
            DDLogError("HazardEvent ShieldUUID not found")
            return
        }
        
        guard let hazardID = hzrdEvntDic["hazardID"] as? String else {
            DDLogError("HazardEvent hazardEventId not found")
            return
        }
        
        guard let isUrgent = hzrdEvntDic["urgent"] as? Bool else {
            DDLogError("HazardEvent urgent not found")
            return
        }
        
        guard let locationDesc = hzrdEvntDic["locationDesc"] as? String else {
            DDLogError("HazardEvent locationDesc not found")
            return
        }
        
        guard let sensorDesc = hzrdEvntDic["deviceDesc"] as? String else {
            DDLogError("HazardEvent deviceDesc not found")
            return
        }
        
        guard let shield = try? Shield.getShieldWithUUID(shieldUUID, moc: moc) else {
            DDLogError("Shield \(shieldUUID) not found")
            return
        }
        
        moc.performBlock {
            
            let hazardEvent = NSEntityDescription.insertNewObjectForEntityForName(StringFromClass(HazardEvent),
                inManagedObjectContext:moc) as! HazardEvent
            hazardEvent.id = hazardID
            hazardEvent.shield = shield
            hazardEvent.isHandled = false
            hazardEvent.isLocal = false
            hazardEvent.isViolated = false
            hazardEvent.latitude = 0
            hazardEvent.longitude = 0
            hazardEvent.title = hazardTitle
            hazardEvent.timestamp = Utils.parseTimestamp(hzrdEvntDic["timestamp"] as? String ?? "2000-00-00T00:00:00,982Z") ?? NSDate()
            hazardEvent.isUrgent = isUrgent
            hazardEvent.locationDesc = locationDesc
            hazardEvent.sensorDesc = sensorDesc
            

            do {
                try moc.save()
            } catch {
                DDLogError("Core Data Error \(error)")
            }
            
            (UIApplication.sharedApplication().delegate as! AppDelegate).showHazardNotification(hazardTitle, hazardEvent: hazardEvent)

        }
    }
    
}

extension Utils {
    
    static let dateISO8601FormaterPoint = Utils.createISO8601DateFormatter(".")
    static let dateISO8601FormaterComma = Utils.createISO8601DateFormatter(",")
    
    static func setPlaceHolderColor(textField:UITextField,color:UIColor) {
        
        textField.attributedPlaceholder = NSAttributedString(string:textField.placeholder!,attributes:[NSForegroundColorAttributeName: color])
        
    }
    
    
    static func createISO8601DateFormatter(commaSeparator:Character) -> NSDateFormatter {
        
        let df = NSDateFormatter()
        df.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        df.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        df.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'" + String(commaSeparator) + "'SSS'Z'"
        
        return df
        
    }
    
    static func parseTimestamp(ts:String?) -> NSDate? {
        
        guard let ts = ts else {
            return nil
        }
        
        var timestamp = dateISO8601FormaterPoint.dateFromString(ts)
        if timestamp == nil {
            timestamp = dateISO8601FormaterComma.dateFromString(ts)
        }
        return timestamp
        
    }
    
    static func DDMMYY(date: NSDate?) -> String?
    {
        guard let _ = date else {
            return ""
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        
        return dateFormatter.stringFromDate(date!)

    }
    
    static func DDMMYY_HHMM(date: NSDate?) -> String
    {
        guard let _ = date else {
            return ""
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy HH:mm"
        
        return dateFormatter.stringFromDate(date!)
        
    }
    
    static func HHMM(date: NSDate?) -> String
    {
        guard let _ = date else {
            return ""
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        return dateFormatter.stringFromDate(date!)
        
    }
    
}

extension Utils {
    
    // MARK: - Sandbox directory
    static let applicationCachesDirectory:NSURL = {
        return NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
    }()
    
    static let applicationLibraryDirectory:NSURL = {
        return NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).first!
    }()
    
    
    static let documentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.first!
    }()
    
}

extension Utils {
    
    static func setResourceAttributeExcludedFromBackupKeyToPath(filePath:String) {
        if let url:NSURL = NSURL(fileURLWithPath: filePath) {
            do {
                try url.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
            } catch let err as NSError {
                fatalError("fatal error - \(err)")
            }
        }
    }
    
}

extension Utils {
    class func registerToAPN(application:UIApplication)
    {
        let okAction = UIMutableUserNotificationAction()
        okAction.identifier = notificationOK
        okAction.title = NSLocalizedString("APNS.OK", comment: "OK Push notification")
        
        okAction.activationMode = .Background
        okAction.destructive = false
        okAction.authenticationRequired = false
        
        let helpAction = UIMutableUserNotificationAction()
        helpAction.identifier = notificationHELP
        helpAction.title = NSLocalizedString("APNS.HELP", comment: "Help Push notification")
        
        helpAction.activationMode = .Foreground
        helpAction.destructive = true
        helpAction.authenticationRequired = false
        
        let checkInCategory = UIMutableUserNotificationCategory()
        checkInCategory.identifier = "CHECKIN_CATEGORY"
        checkInCategory.setActions([okAction], forContext: .Default)
        checkInCategory.setActions([okAction], forContext: .Minimal)
        
        let categories:NSSet = NSSet(array: [checkInCategory])
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: categories as? Set<UIUserNotificationCategory>)
        
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
    }
}

extension Utils {
    class var isCredentialsPresent: Bool {
        
        do {
            
            let (username,password) = try self.getCredintials()
            
            if username != nil && username != "" && password != nil && password != "" {
                return true
            }
            
        } catch {
            return false
        }
        
        return false
    }
    
    
    class func getCredintials() throws -> (String?, String?)
    {
        let keychain = UICKeyChainStore(service:keyChainDomain)
        
        do {
            return (try keychain.stringForKey("appUsername", error: ()), try keychain.stringForKey("appPassword", error: ()))
        } catch {
            DDLogError("KeyChain Error \(error)")
            throw error
        }
    }
    
    class func writeCredential(user:String,password: String) {
        
        let keychain = UICKeyChainStore(service:keyChainDomain)
        keychain.setString(password, forKey: "appPassword")
        keychain.setString(user, forKey: "appUsername")
        
        UserPreferences.username = user
        
    }
    
    class func removeCredential() {
        let keychain = UICKeyChainStore(service:keyChainDomain)
        keychain.removeAllItems()
    }
    
}

public func StringFromClass(obj: AnyClass) -> String {
    return obj.description().componentsSeparatedByString(".").last!
}
extension UILabel {
    
    func setOrangeHazardousText()
    {
        self.textColor = HazardOrange_TintColor
    }
    
    func setRedHazardousText()
    {
        self.textColor = HazardRed_TintColor
    }
    
}

extension UIView {
    
    func setOrangeHazardousBackground()
    {
        self.backgroundColor = HazardOrange_TintColor
    }
    
    func clearBackgroundColor()
    {
        self.backgroundColor = UIColor.clearColor()
    }
    
    func setRedHazardousBackground()
    {
        self.backgroundColor = HazardRed_TintColor
    }
    
}

extension UIImageView {
    
    func setOrangeBackgroundImage()
    {
        self.image = UIImage(named: "dotOrange")
    }
    
    func setRedBackgroundImage()
    {
        self.image = UIImage(named: "dotRed")
    }
    
    func setFullBackgroundImage()
    {
        self.image = UIImage(named: "dotFull")
    }
    
    func setOutlineBackgroundImage()
    {
        self.image = UIImage(named: "dotOutline")
    }
    
    func setHazardousBackgroundImage()
    {
        self.image = UIImage(named: "hazardousCircle")
    }
    
    func setUrgentBackgroundImage()
    {
        self.image = UIImage(named: "urgentCircle")
    }
    
    func clearImage()
    {
        self.image = nil
    }
}

