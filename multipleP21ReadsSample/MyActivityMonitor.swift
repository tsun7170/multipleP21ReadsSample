//
//  MyActivityMonitor.swift
//  swiftP21read
//
//  Created by Yoshida on 2021/07/10.
//  Copyright © 2021 Tsutomu Yoshida, Minokamo, Japan. All rights reserved.
//

import Foundation
import SwiftSDAIcore
import SwiftAP242PDMkit

//MARK: - activity monitor
class MyActivityMonitor:
  ExternalReferenceLoader.ActivityMonitor, @unchecked Sendable
{

  //MARK: ExternalReferenceLoader.ActivityMonitor overrides
  override func startedLoading(externalReference: ExternalReferenceLoader.ExternalReference)
  {
    super.startedLoading(externalReference: externalReference)

    let terminator = concurrently ? "\n" : ""
    print("\n loading file: \(externalReference.name) ", terminator: terminator)
    entityCount = 0
  }

  override func completedLoading(externalReference: ExternalReferenceLoader.ExternalReference)
  {
    super.completedLoading(externalReference: externalReference)

    print(" file: \(externalReference.name) completed loading with status(\(externalReference.status))")
  }

  override func identified(
    children: [ExternalReferenceLoader.ExternalReference],
    originatedFrom upstream: ExternalReferenceLoader.ExternalReference)
  {
    super.identified(children: children, originatedFrom: upstream)

    print(" file: \(upstream.name) contains \(children.count) external references.")
  }



  //MARK: P21Decode.ActivityMonitor overrides
  override func tokenStreamDidSet(error p21Error: P21Decode.P21Error) {
    print("\n error detected on token stream[\(externalReference.name)]: \(p21Error)")
  }

  override func parserDidSet(error p21Error: P21Decode.P21Error) {
    print("\n error detected on parser[\(externalReference.name)]: \(p21Error)")
  }

  override func exchangeStructureDidSet(error exError: String) {
    print("\n error detected on exchange structure[\(externalReference.name)]: \(exError)")
  }

  override func decoderDidSet(error decoderError: P21Decode.Decoder.Error) {
    print("\n error detected on decoder[\(externalReference.name)]: \(decoderError)")
  }

  override func scannerDidDetectNewLine(lineNumber: Int) {
    if concurrently { return }
    if lineNumber % 1000 == 0 			{ print("+", terminator: "") }
    else if lineNumber % 100 == 0 	{ print(".", terminator: "") }
  }

  var entityCount = 0
  override func decoderResolved(entityInstanceName: P21Decode.ExchangeStructure.EntityInstanceName) {
    entityCount += 1
    if concurrently { return }
    if entityCount % 1000 == 0 			{ print("*", terminator: "") }
    else if entityCount % 100 == 0 	{ print(".", terminator: "") }
  }

  override func startedParsingHeaderSection() {
    let terminator = concurrently ? "\n" : ""
    print("\n parsing header section[\(externalReference.name)]: ", terminator: terminator)
  }

  override func startedParsingAnchorSection() {
    let terminator = concurrently ? "\n" : ""
    print("\n parsing anchor section[\(externalReference.name)]: ", terminator: terminator)
  }

  override func startedParsingReferenceSection() {
    let terminator = concurrently ? "\n" : ""
    print("\n parsing reference section[\(externalReference.name)]: ", terminator: terminator)
  }

  override func startedParsingDataSection() {
    let terminator = concurrently ? "\n" : ""
    print("\n parsing data section[\(externalReference.name)]: ", terminator: terminator)

  }

  override func completedParsing() {
    print("\n completed parsing[\(externalReference.name)].")
  }

  override func startedResolvingEntityInstances() {
    let terminator = concurrently ? "\n" : ""
    print(" resolving entity instances[\(externalReference.name)]: ", terminator: terminator)

  }

  override func completedResolving() {
    print("\n completed resolving[\(externalReference.name)].")
  }

}
