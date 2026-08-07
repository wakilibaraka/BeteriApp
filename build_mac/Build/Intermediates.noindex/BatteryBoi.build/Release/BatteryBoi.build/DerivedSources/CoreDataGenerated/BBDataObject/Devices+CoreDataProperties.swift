//
//  Devices+CoreDataProperties.swift
//  
//
//  Created by Emmanuel Baraka Ongau on 8/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias DevicesCoreDataPropertiesSet = NSSet

extension Devices {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Devices> {
        return NSFetchRequest<Devices>(entityName: "Devices")
    }

    @NSManaged public var address: String?
    @NSManaged public var battery: Int16
    @NSManaged public var last_connected: Date?
    @NSManaged public var last_updates: Date?
    @NSManaged public var name: String?
    @NSManaged public var subtype: String?
    @NSManaged public var type: String?
    @NSManaged public var vendor: String?

}

extension Devices : Identifiable {

}
