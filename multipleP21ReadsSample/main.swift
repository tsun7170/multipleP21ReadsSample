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

let stopwatch = ContinuousClock()
let beginRun = stopwatch.now
print(Date.now.formatted())

//MARK: identify the input p21 data file
let testDataFolder = ProcessInfo.processInfo.environment["TEST_DATA_FOLDER"]!

///https://www.cax-if.org/cax/cax_stepLib.php
///(not accessible any more.)
let url = URL(fileURLWithPath: testDataFolder + "CAx STEP FILE LIBRARY/s1-c5-214/s1-c5-214.stp")

print("\n input: \(url.lastPathComponent)\n\n")

//MARK: create output repository
let repository = SDAISessionSchema.SdaiRepository(name: "example", description: "example repository")

let schemaInstanceName = "example"

//MARK: create SDAI-session
let session = SDAI.openSession(
  knownServers: [repository],
  //  maxConcurrency: 1
)

let _ = session.startEventRecording()
session.open(repository: repository)

//MARK: - start RW transaction
let disposition = await session.performTransactionRW(
  output: [String:ExternalReferenceLoader.ExternalReference].self)
{ transaction in

  //MARK: prepare the acceptable step schema list
  let schemaList: P21Decode.SchemaList = [
    "AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF { 1 0 10303 442 4 1 4 }": ap242.self,
    "AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF { 1 0 10303 442 3 1 4 }": ap242.self,
    "AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF { 1 0 10303 442 1 1 4 }": ap242.self,
    "AP203_CONFIGURATION_CONTROLLED_3D_DESIGN_OF_MECHANICAL_PARTS_AND_ASSEMBLIES_MIM_LF  { 1 0 10303 403 3 1 4}": ap242.self,
    "AP203_CONFIGURATION_CONTROLLED_3D_DESIGN_OF_MECHANICAL_PARTS_AND_ASSEMBLIES_MIM_LF { 1 0 10303 403 2 1 2}": ap242.self,
    "CONFIG_CONTROL_DESIGN": ap242.self,
    "CONFIGURATION_CONTROL_3D_DESIGN_ED2_MIM_LF { 1 0 10303 403 1 1 4}": ap242.self,
    "AUTOMOTIVE_DESIGN { 1 0 10303 214 1 1 1 1 }": ap242.self,
  ]

  //MARK: create external reference loader
  guard let loader = ExternalReferenceLoader(
    repository: repository,
    schemaList: schemaList,
    masterFile: url,
    monitorType: MyActivityMonitor.self )
  else {
    print("failed to create ExternalReferenceLoader")
    exit(1)
  }

  //MARK: decode p21 char stream
//  await loader.decode(transaction: transaction)
  await loader.decodeConcurrently(transaction: transaction)


  //MARK: create a schema instance containing all models
  let createdModels = await loader.sdaiModels

  // create a schema instance
  guard let schema = createdModels.first?.underlyingSchema,
        let schemaInstance = transaction.createSchemaInstance(
          repository: repository, name: schemaInstanceName, schema: schema)
  else {
    SDAI.raiseErrorAndTrap(.SY_ERR, detail: "could not create schema instance")
  }

  // put all the decoded models into a schema instance
  for model in createdModels {
    let _ = await transaction.addSdaiModel(instance: schemaInstance, model: model)
  }

  return await .commit(loader.externalReferences)
}
guard case .commit(let externalReferences) = disposition
else {
  fatalError("transaction aborted")
}
let durationDecode = beginRun.duration(to: stopwatch.now)
//MARK: end RW transaction
print("\n(1) decode complete")
print("total duration: \(durationDecode/*.formatted()*/)\n\n")


//MARK: - start RO transaction
await session.performTransactionRO { transaction in
  //MARK: list loaded
  for (i,extref) in externalReferences
    .values
    .sorted(by: {
      if $0.level < $1.level { return true }
      return ($0.serial < $1.serial)
    }).enumerated()
  {
    print("")
    print("[\(i)]\t LEVEL.\(extref.level)\t \(extref.name)" )
    print("\t STATUS   = \(extref.status)")
    print("\t UPSTREAM = \(extref.upStream?.name ?? "none")")
    print("\t MODELS   = \(extref.sdaiModels.map{$0.name})")
    for (j,linkage) in extref.externalShapeDefinitionLinkages.enumerated() {
      let productId = linkage.master.DEFINITION?.DEFINITION?.FORMATION?.OF_PRODUCT?.ID?.asSwiftType ?? "(no product id)"
      let productName = linkage.master.DEFINITION?.DEFINITION?.FORMATION?.OF_PRODUCT?.NAME?.asSwiftType ?? "(no product name)"
      let shapeId = linkage.master.USED_REPRESENTATION?.ID?.asSwiftType ?? "(no shape rep id)"
      let shapeName = linkage.master.USED_REPRESENTATION?.NAME?.asSwiftType ?? "(no shape name)"

      print("\t LINKAGE<\(j)>\t ID = '\(productId)'/'\(shapeId)'\t NAME = '\(productName)'/'\(shapeName)'")
      print("\t\t MASTER = \(linkage.master)")
      print("\t\t DETAIL = \(linkage.detail)")
    }
  }
  return .commit(Void())
}
//MARK: end RO transaction
print("\n(2) inspection complete\n\n")

//MARK: - start VA transaction for validation
await session.performTransactionVA { transaction in
  guard
    let si = repository.contents.findSchemaInstance(named: schemaInstanceName),
    let schemaInstance = transaction.promoteSchemaInstanceToReadWrite(instance: si)
  else {
    SDAI.raiseErrorAndContinue(.SY_ERR, detail: "could not obtain schema instance[\(schemaInstanceName)] in RW mode")
    return .abort
  }

  let validationMonitor = MyValidationMonitor()

  //MARK: all validations
  let doAllValidation = true
  if doAllValidation {
    let validationPassed = await transaction.validateSchemaInstanceAsync(
      instance: schemaInstance,
      option: .recordFailureOnly,
      monitor: validationMonitor)

    print("\n SCHEMA INSTANCE VALIDATION RESULT\n validationPassed?: \(validationPassed)")

    print("\n instanceReferenceDomainValidationRecord: \(schemaInstance.instanceReferenceDomainValidationRecord, default: "nil")")

    print("\n globalRuleValidationRecord: \(schemaInstance.globalRuleValidationRecordDescription)"  )

    print("\n uniquenessRuleValidationRecord: \( schemaInstance.uniquenessRuleValidationRecordDescription)")

    print("\n whereRuleValidationRecord: \( schemaInstance.whereRuleValidationRecord, default: "nil")" )
  }

  return .commit
}
//MARK: end VA transaction
print("\n(3) validation complete\n\n")



print("normal end of execution")
let durationRun = beginRun.duration(to: stopwatch.now)
print(Date.now.formatted())
print("total duration: \(durationRun.formatted())")
