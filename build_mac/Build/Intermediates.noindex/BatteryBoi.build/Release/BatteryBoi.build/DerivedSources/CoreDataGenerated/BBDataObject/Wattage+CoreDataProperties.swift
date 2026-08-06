//
//  Wattage+CoreDataProperties.swift
//  
//
//  Created by Emmanuel Baraka Ongau on 8/6/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias WattageCoreDataPropertiesSet = NSSet

extension Wattage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Wattage> {
        return NSFetchRequest<Wattage>(entityName: "Wattage")
    }

    @NSManaged public var device: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var wattage: Double

}

extension Wattage : Identifiable {

}
