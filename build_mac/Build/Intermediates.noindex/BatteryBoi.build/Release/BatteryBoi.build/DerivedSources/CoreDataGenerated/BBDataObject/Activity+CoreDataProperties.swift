//
//  Activity+CoreDataProperties.swift
//  
//
//  Created by Emmanuel Baraka Ongau on 8/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ActivityCoreDataPropertiesSet = NSSet

extension Activity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Activity> {
        return NSFetchRequest<Activity>(entityName: "Activity")
    }

    @NSManaged public var charge: Int64
    @NSManaged public var device: String?
    @NSManaged public var state: String?
    @NSManaged public var timestamp: Date?

}

extension Activity : Identifiable {

}
