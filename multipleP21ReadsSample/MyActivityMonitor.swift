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
	override func startedLoading(externalReference: ExternalReferenceLoader.ExternalReference) {
		print("\n loading file: \(externalReference.name) ", terminator: "")
		entityCount = 0
	}
	override func completedLoading(externalReference: ExternalReferenceLoader.ExternalReference) {
		print(" file: \(externalReference.name) completed loading with status(\(externalReference.status))")
	}
	override func identified(externalReferences: [ExternalReferenceLoader.ExternalReference], 
													 originatedFrom upstream: ExternalReferenceLoader.ExternalReference) {
		print(" file: \(upstream.name) contains \(externalReferences.count) external references.")
	}

	
	
	//MARK: P21Decode.ActivityMonitor overrides
	override func tokenStreamDidSet(error p21Error: P21Decode.P21Error) {
		print("\n error detected on token stream: \(p21Error)")
	}
	
	override func parserDidSet(error p21Error: P21Decode.P21Error) {
		print("\n error detected on parser: \(p21Error)")
	}
	
	override func exchangeStructureDidSet(error exError: String) {
		print("\n error detected on exchange structure: \(exError)")
	}
	
	override func decoderDidSet(error decoderError: P21Decode.Decoder.Error) {
		print("\n error detected on decoder: \(decoderError)")
	}
	
	override func scannerDidDetectNewLine(lineNumber: Int) {
		if lineNumber % 1000 == 0 			{ print("+", terminator: "") }
		else if lineNumber % 100 == 0 	{ print(".", terminator: "") }
	}
	
	var entityCount = 0
	override func decoderResolved(entityInstanceName: P21Decode.ExchangeStructure.EntityInstanceName) {
		entityCount += 1
		if entityCount % 1000 == 0 			{ print("*", terminator: "") }
		else if entityCount % 100 == 0 	{ print(".", terminator: "") }		
	}
	
	override func startedParsingHeaderSection() {
		print("\n parsing header section: ", terminator: "")
	}
	
	override func startedParsingAnchorSection() {
		print("\n parsing anchor section: ", terminator: "")
	}
	
	override func startedParsingReferenceSection() {
		print("\n parsing reference section: ", terminator: "")
	}
	
	override func startedParsingDataSection() {
		print("\n parsing data section: ", terminator: "")

	}
	
	override func completedParsing() {
		print("\n completed parsing.")
	}
	
	override func startedResolvingEntityInstances() {
		print(" resolving entity instances: ", terminator: "")

	}
	
	override func completedResolving() {
		print("\n completed resolving.")
	}

}
