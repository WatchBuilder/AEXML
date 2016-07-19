//
// AEXML.swift
//
// Copyright (c) 2014 Marko Tadić <tadija@me.com> http://tadija.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

// MARK: Equatable

private func !=(lhs: [NSObject: AnyObject], rhs: [NSObject: AnyObject]) -> Bool {
	for (key, lhsValue) in lhs {
		if let rhsValue: AnyObject = rhs[key] {
			if !(lhsValue === rhsValue) { return true }
		} else { return true }
	}
	return false
}

public func ==(lhs: AEXMLElement, rhs: AEXMLElement) -> Bool {
	if lhs.name != rhs.name { return false }
	if lhs.value != rhs.value { return false }
	if lhs.parent != rhs.parent { return false }
	if lhs.children != rhs.children { return false }
	if lhs.attributes != rhs.attributes { return false }
	return true
}

public class AEXMLElement: Equatable {

	// MARK: Properties

	public private(set) weak var parent: AEXMLElement?
	public private(set) var children: [AEXMLElement] = [AEXMLElement]()

	public let name: String
	public var value: String?
	public var attributes: [NSObject : AnyObject]

	public var stringValue: String {
		return value ?? String()
	}
	public var boolValue: Bool {
		return stringValue.lowercased() == "true" || Int(stringValue) == 1 ? true : false
	}
	public var escapedStringValue: String {
		// We need to make sure "&" is escaped first. Not doing this may break escaping the other characters.
		var escapedString = stringValue.replacingOccurrences(of: "&", with: "&amp;", options: NSString.CompareOptions.literal, range: nil)

		let escapeChars = ["<" : "&lt;", ">" : "&gt;", "\"" : "&quot;", "'" : "&apos;"]

		// replace the other four special characters
		for (char, echar) in escapeChars {
			escapedString = escapedString.replacingOccurrences(of: char, with: echar, options: NSString.CompareOptions.literal, range: nil)
		}

		return escapedString
	}
	public var intValue: Int {
		return Int(stringValue) ?? 0
	}
	public var doubleValue: Double {
		return (stringValue as NSString).doubleValue
	}

	// MARK: Lifecycle

	public init(_ name: String, value: String? = nil, attributes: [NSObject : AnyObject] = [NSObject : AnyObject]()) {
		self.name = name
		self.value = value
		self.attributes = attributes
	}

	// MARK: XML Read

	// this element name is used when unable to find element
	public class var errorElementName: String { return "AEXMLError" }

	// non-optional first element with given name (<error> element if not exists)
	public subscript(key: String) -> AEXMLElement {
		if name == AEXMLElement.errorElementName {
			return self
		} else {
			let filtered = children.filter { $0.name == key }
			return filtered.count > 0 ? filtered.first! : AEXMLElement(AEXMLElement.errorElementName, value: "element <\(key)> not found")
		}
	}

	public var all: [AEXMLElement]? {
		return parent?.children.filter { $0.name == self.name }
	}

	public var first: AEXMLElement? {
		return all?.first
	}

	public var last: AEXMLElement? {
		return all?.last
	}

	public var count: Int {
		return all?.count ?? 0
	}

	public func allWithAttributes <K: NSObject, V: AnyObject where K: Equatable, V: Equatable> (_ attributes: [K : V]) -> [AEXMLElement]? {
		var found = [AEXMLElement]()
		if let elements = all {
			for element in elements {
				var countAttributes = 0
				for (key, value) in attributes {
					if element.attributes[key] as? V == value {
						countAttributes += 1
					}
				}
				if countAttributes == attributes.count {
					found.append(element)
				}
			}
			return found.count > 0 ? found : nil
		} else {
			return nil
		}
	}

	public func countWithAttributes <K: NSObject, V: AnyObject where K: Equatable, V: Equatable> (_ attributes: [K : V]) -> Int {
		return allWithAttributes(attributes)?.count ?? 0
	}

	// MARK: XML Write

	public func addChild(_ child: AEXMLElement) -> AEXMLElement {
		child.parent = self
		children.append(child)
		return child
	}

	public func addChild(name: String, value: String? = nil, attributes: [NSObject : AnyObject] = [NSObject : AnyObject]()) -> AEXMLElement {
		let child = AEXMLElement(name, value: value, attributes: attributes)
		return addChild(child)
	}

	public func addAttribute(_ name: NSObject, value: AnyObject) {
		attributes[name] = value
	}

	public func addAttributes(_ attributes: [NSObject : AnyObject]) {
		for (attributeName, attributeValue) in attributes {
			addAttribute(attributeName, value: attributeValue)
		}
	}

	public func removeFromParent() {
		parent?.removeChild(self)
	}

	private func removeChild(_ child: AEXMLElement) {
		if let childIndex = children.index(of: child) {
			children.remove(at: childIndex)
		}
	}

	private var parentsCount: Int {
		var count = 0
		var element = self
		while let parent = element.parent {
			count += 1
			element = parent
		}
		return count
	}

	private func indentation(_ count: Int) -> String {
		var indent = String()
		if count > 0 {
			for _ in 0..<count {
				indent += "\t"
			}
		}
		return indent
	}

	public var xmlString: String {
		var xml = String()

		// open element
		xml += indentation(parentsCount - 1)
		xml += "<\(name)"

		if attributes.count > 0 {
			// insert attributes
			for (key, value) in attributes {
				xml += " \(key)=\"\(value)\""
			}
		}

		if value == nil && children.count == 0 {
			// close element
			xml += " />"
		} else {
			if children.count > 0 {
				// add children
				xml += ">\n"
				for child in children {
					xml += "\(child.xmlString)\n"
				}
				// add indentation
				xml += indentation(parentsCount - 1)
				xml += "</\(name)>"
			} else {
				// insert string value and close element
				xml += ">\(escapedStringValue)</\(name)>"
			}
		}

		return xml
	}

	public var xmlStringCompact: String {
		let chars = CharacterSet(charactersIn: "\n\t")
		return xmlString.components(separatedBy: chars).joined(separator: "")
	}
}

// MARK: -

public class AEXMLDocument: AEXMLElement {

	// MARK: Properties

	public let version: Double
	public let encoding: String
	public let standalone: String

	public var root: AEXMLElement {
		return children.count == 1 ? children.first! : AEXMLElement(AEXMLElement.errorElementName, value: "XML Document must have root element.")
	}

	// MARK: Lifecycle

	public init(version: Double = 1.0, encoding: String = "utf-8", standalone: String = "no", root: AEXMLElement? = nil) {
		// set document properties
		self.version = version
		self.encoding = encoding
		self.standalone = standalone

		// init super with default name
		super.init("AEXMLDocument")

		// document has no parent element
		parent = nil

		// add root element to document (if any)
		if let rootElement = root {
			_ = addChild(rootElement)
		}
	}

	public convenience init(version: Double = 1.0, encoding: String = "utf-8", standalone: String = "no", xmlData: Data) throws {
		self.init(version: version, encoding: encoding, standalone: standalone)
		if let parseError = readXMLData(xmlData) {
			throw parseError
		}
	}

	// MARK: Read XML

	public func readXMLData(_ data: Data) -> NSError? {
		children.removeAll(keepingCapacity: false)
		let xmlParser = AEXMLParser(xmlDocument: self, xmlData: data)
		return xmlParser.tryParsing() ?? nil
	}

	// MARK: Override

	public override var xmlString: String {
		var xml =  "<?xml version=\"\(version)\" encoding=\"\(encoding)\" standalone=\"\(standalone)\"?>\n"
		for child in children {
			xml += child.xmlString
		}
		return xml
	}

}

// MARK: -

class AEXMLParser: NSObject, XMLParserDelegate {

	// MARK: Properties

	let xmlDocument: AEXMLDocument
	let xmlData: Data

	var currentParent: AEXMLElement?
	var currentElement: AEXMLElement?
	var currentValue = String()
	var parseError: NSError?

	// MARK: Lifecycle

	init(xmlDocument: AEXMLDocument, xmlData: Data) {
		self.xmlDocument = xmlDocument
		self.xmlData = xmlData
		currentParent = xmlDocument
		super.init()
	}

	// MARK: XML Parse

	func tryParsing() -> NSError? {
		var success = false
		let parser = XMLParser(data: xmlData)
		parser.delegate = self
		success = parser.parse()
		return success ? nil : parseError
	}

	// MARK: NSXMLParserDelegate

	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		currentValue = String()
		currentElement = currentParent?.addChild(name: elementName, attributes: attributeDict)
		currentParent = currentElement
	}

	func parser(_ parser: XMLParser, foundCharacters string: String) {
		currentValue += string ?? String()
		let newValue = currentValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		currentElement?.value = newValue == String() ? nil : newValue
	}

	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		currentParent = currentParent?.parent
		currentElement = nil
	}

	func parser(_ parser: XMLParser, parseErrorOccurred parseError: NSError) {
		self.parseError = parseError
	}

}
