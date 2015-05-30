//
//  AEXMLExtensions.swift
//  WatchBuilder
//
//  Created by William Kent on 5/27/15.
//  Copyright (c) 2015 William Kent. All rights reserved.
//

import Foundation

public extension AEXMLElement {
    // XMLNamespaceURLsByPrefix, defaultXMLNamespaceURL, getXMLNamespacePrefix(forURL:),
    // and getXMLNamespaceURL(forPrefix:) all call the same method on their parent,
    // if any, before returning nil.
    
    public var XMLNamespaceURLsByPrefix: [String: String] {
        get {
            var retval = [String: String]()
            
            for (key, value) in attributes {
                let prefix = "xmlns:"
                let stringKey = key as! String
                if stringKey.hasPrefix(prefix) {
                    let trimmedKey = stringKey.substringFromIndex(advance(stringKey.startIndex, (prefix as NSString).length))
                    retval[trimmedKey] = value as? String
                }
            }
            
            for (key, value) in (parent?.XMLNamespaceURLsByPrefix ?? [:]) {
                retval[key] = value
            }
            
            return retval
        }
    }
    
    public var defaultXMLNamespaceURL: String? {
        get {
            if let URL: AnyObject = attributes["xmlns"] {
                return URL as? String
            } else {
                return parent?.defaultXMLNamespaceURL
            }
        }
        
        set {
            if let newValue = newValue {
                attributes["xmlns"] = newValue as NSString
            } else {
                attributes.removeValueForKey("xmlns")
            }
        }
    }
    
    public func getXMLNamespacePrefix(forURL URL: String) -> String? {
        for (key, value) in XMLNamespaceURLsByPrefix {
            if value == URL {
                return key
            }
        }
        
        return parent?.getXMLNamespacePrefix(forURL: URL)
    }
    
    public func getXMLNamespaceURL(forPrefix prefix: String) -> String? {
        if let URL = XMLNamespaceURLsByPrefix[prefix] {
            return URL
        } else {
            return parent?.getXMLNamespaceURL(forPrefix: prefix)
        }
    }
    
    public func setXMLNamespace(#prefix: String, URL: String) {
        attributes["xmlns:\(prefix)"] = URL
    }
    
    public func clearXMLNamespaceMapping(#prefix: String) {
        attributes.removeValueForKey("xmlns:\(prefix)")
    }
    
    public func containsXMLNamespaceMapping(#prefix: String) -> Bool {
        if prefix == "" { return defaultXMLNamespaceURL != nil }
        return contains(XMLNamespaceURLsByPrefix.keys, prefix)
    }
    
    public func containsXMLNamespaceMapping(#namespaceURL: String) -> Bool {
        if namespaceURL == defaultXMLNamespaceURL { return true }
        return contains(XMLNamespaceURLsByPrefix.values, namespaceURL)
    }
    
    public func child(#elementName: String, namespaceURL: String) -> AEXMLElement? {
        if let defaultXMLNamespaceURL = defaultXMLNamespaceURL {
            if defaultXMLNamespaceURL == namespaceURL {
                for child in children {
                    if child.name == elementName {
                        return child
                    }
                }
            }
        }
        
        for (prefix, href) in XMLNamespaceURLsByPrefix {
            if namespaceURL == href {
                let annotatedName = "\(prefix):\(elementName)"
                for child in children {
                    if child.name == annotatedName {
                        return child
                    }
                }
            }
        }
        
        return nil
    }
    
    public func attribute(#name: String, namespaceURL: String) -> String? {
        if let defaultXMLNamespaceURL = defaultXMLNamespaceURL {
            if defaultXMLNamespaceURL == namespaceURL {
                return attributes[name] as? String
            }
        }
        
        for (prefix, href) in XMLNamespaceURLsByPrefix {
            if namespaceURL == href {
                let annotatedName = "\(prefix):\(name)"
                for (attrName, attrValue) in attributes {
                    if attrName == annotatedName {
                        return attrValue as? String
                    }
                }
            }
        }
        
        return nil
    }
    
    public func setAttribute(#name: String, namespaceURL: String, value: String) {
        if let defaultXMLNamespaceURL = defaultXMLNamespaceURL {
            if defaultXMLNamespaceURL == namespaceURL {
                attributes[name] = value
            }
        }
        
        for (prefix, href) in XMLNamespaceURLsByPrefix {
            if namespaceURL == href {
                attributes["\(prefix):\(name)"] = value
            }
        }
        
        // If this point is reached, the namespaceURL was not matched to a prefix.
        // In this case, create one using an automatically generated name.
        var index = 0
        while containsXMLNamespaceMapping(prefix: "ns\(index)") {
            index++
        }
        
        setXMLNamespace(prefix: "ns\(index)", URL: namespaceURL)
        return attributes["ns\(index):\(name)"] = value
    }
    
    public func addChild(#name: String, namespaceURL: String, value: String? = nil, attributes: [NSObject : AnyObject] = [NSObject : AnyObject]()) -> AEXMLElement {
        if let defaultXMLNamespaceURL = defaultXMLNamespaceURL {
            if defaultXMLNamespaceURL == namespaceURL {
                return addChild(name: name, value: value, attributes: attributes)
            }
        }
        
        for (prefix, href) in XMLNamespaceURLsByPrefix {
            if namespaceURL == href {
                return addChild(name: "\(prefix):\(name)", value: value, attributes: attributes)
            }
        }
        
        // If this point is reached, the namespaceURL was not matched to a prefix.
        // In this case, create one using an automatically generated name.
        var index = 0
        while containsXMLNamespaceMapping(prefix: "ns\(index)") {
            index++
        }
        
        setXMLNamespace(prefix: "ns\(index)", URL: namespaceURL)
        return addChild(name: "ns\(index):\(name)", value: value, attributes: attributes)
    }
}
