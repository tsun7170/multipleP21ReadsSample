//
//  main.swift
//  multipleP21ReadsSample
//
//  Created by Yoshida on 2021/10/05.
//  Copyright © 2021 Tsutomu Yoshida, Minokamo, Japan. All rights reserved.
//

import Foundation
import SwiftSDAIcore
import SwiftSDAIap242
import SwiftAP242PDMkit

//MARK: identify the input p21 data file
let testDataFolder = ProcessInfo.processInfo.environment["TEST_DATA_FOLDER"]!

let url = URL(fileURLWithPath: testDataFolder + "CAx STEP FILE LIBRARY/s1-c5-214/s1-c5-214.stp")


//MARK: create output repository
let repository = SDAISessionSchema.SdaiRepository(name: "example", description: "example repository")

//MARK: prepare the acceptable step schema list
let schemaList: P21Decode.SchemaList = [
	"AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF { 1 0 10303 442 3 1 4 }": AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF.self,
	"AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF { 1 0 10303 442 1 1 4 }": AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF.self,
	"AP203_CONFIGURATION_CONTROLLED_3D_DESIGN_OF_MECHANICAL_PARTS_AND_ASSEMBLIES_MIM_LF  { 1 0 10303 403 3 1 4}": AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF.self,
	"AP203_CONFIGURATION_CONTROLLED_3D_DESIGN_OF_MECHANICAL_PARTS_AND_ASSEMBLIES_MIM_LF { 1 0 10303 403 2 1 2}": AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF.self,
	"CONFIG_CONTROL_DESIGN": AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF.self,
	"CONFIGURATION_CONTROL_3D_DESIGN_ED2_MIM_LF { 1 0 10303 403 1 1 4}": AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF.self,
	"AUTOMOTIVE_DESIGN { 1 0 10303 214 1 1 1 1 }": AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF.self,
]

//MARK: create external reference loader
let monitor = MyActivityMonitor()
guard let loader = ExternalReferenceLoader(repository: repository, 
																		 schemaList: schemaList, 
																		 masterFile: url, 
																		 monitor: monitor)
else {
	print("failed to create ExternalReferenceLoader")
	exit(1)
}

//MARK: decode
loader.decode()

//MARK: list loaded
for (i,extref) in loader.externalReferenceList.enumerated() {
	print("")
	print("[\(i)]\t LEVEL.\(extref.level)\t \(extref.name)" )
	print("\t STATUS   = \(extref.status)")
	print("\t UPSTREAM = \(extref.upStream?.name ?? "none")")
	print("\t MODELS   = \(extref.sdaiModels.map{$0.name})")
	for (j,linkage) in extref.externalShapeDefinitionLinkages.enumerated() {
		let productId = linkage.master.DEFINITION.DEFINITION.FORMATION?.OF_PRODUCT.ID.asSwiftType ?? "(no product id)"
		let productName = linkage.master.DEFINITION.DEFINITION.FORMATION?.OF_PRODUCT.NAME.asSwiftType ?? "(no product name)"
		let shapeId = linkage.master.USED_REPRESENTATION.ID?.asSwiftType ?? "(no shape rep id)"
		let shapeName = linkage.master.USED_REPRESENTATION.NAME.asSwiftType
		
		print("\t LINKAGE<\(j)>\t ID = '\(productId)'/'\(shapeId)'\t NAME = '\(productName)'/'\(shapeName)'")
		print("\t\t MASTER = \(linkage.master)")
		print("\t\t DETAIL = \(linkage.detail)")
	}
}

//MARK: create a schema instance containing all models
let allmodels = repository.createSchemaInstance(name: url.lastPathComponent, 
																								schema: ap242.schemaDefinition)
allmodels.add(models: loader.sdaiModels)
allmodels.mode = .readOnly

//MARK: validation
var doAllValidaton = false
if doAllValidaton {
	let validationPassed = allmodels.validateAllConstraints(monitor: MyValidationMonitor())
	
	print("\n\n validationPassed: ", validationPassed)
	print("\n glovalRuleValidationRecord: \(String(describing: allmodels.globalRuleValidationRecord))"  )
	print("\n uniquenessRuleValidationRecord: \(String(describing: allmodels.uniquenessRuleValidationRecord))")
	print("\n whereRuleValidationRecord: \(String(describing: allmodels.whereRuleValidationRecord))" )
	print("")
}

print("")
