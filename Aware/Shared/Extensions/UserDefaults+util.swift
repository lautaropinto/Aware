//
//  UserDefaults+util.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/3/25.
//

import Foundation

// MARK: - UserDefaults Key-based Extension
extension UserDefaults {
    
    // MARK: - Generic Value Setting and Getting
    
    /// Sets a value for the specified key
    /// - Parameters:
    ///   - value: The value to store
    ///   - key: The key to associate with the value
    func set<T>(_ value: T?, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets a value for the specified key with a default fallback
    /// - Parameters:
    ///   - key: The key to retrieve the value for
    ///   - defaultValue: The default value to return if key doesn't exist
    /// - Returns: The stored value or the default value
    func value<T>(for key: String, defaultValue: T) -> T {
        return object(forKey: key) as? T ?? defaultValue
    }
    
    /// Gets an optional value for the specified key
    /// - Parameter key: The key to retrieve the value for
    /// - Returns: The stored value or nil if it doesn't exist
    func value<T>(for key: String) -> T? {
        return object(forKey: key) as? T
    }
    
    // MARK: - Specific Type Convenience Methods
    
    /// Sets a string value for the specified key
    func setString(_ value: String?, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets a string value for the specified key
    func string(for key: String, defaultValue: String = "") -> String {
        return string(forKey: key) ?? defaultValue
    }
    
    /// Sets an integer value for the specified key
    func setInt(_ value: Int, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets an integer value for the specified key
    func int(for key: String, defaultValue: Int = 0) -> Int {
        return object(forKey: key) as? Int ?? defaultValue
    }
    
    /// Sets a boolean value for the specified key
    func setBool(_ value: Bool, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets a boolean value for the specified key
    func bool(for key: String, defaultValue: Bool = false) -> Bool {
        return object(forKey: key) as? Bool ?? defaultValue
    }
    
    /// Sets a double value for the specified key
    func setDouble(_ value: Double, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets a double value for the specified key
    func double(for key: String, defaultValue: Double = 0.0) -> Double {
        return object(forKey: key) as? Double ?? defaultValue
    }
    
    /// Sets a float value for the specified key
    func setFloat(_ value: Float, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets a float value for the specified key
    func float(for key: String, defaultValue: Float = 0.0) -> Float {
        return object(forKey: key) as? Float ?? defaultValue
    }
    
    /// Sets a Date value for the specified key
    func setDate(_ value: Date?, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets a Date value for the specified key
    func date(for key: String) -> Date? {
        return object(forKey: key) as? Date
    }
    
    /// Sets a Data value for the specified key
    func setData(_ value: Data?, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets a Data value for the specified key
    func data(for key: String) -> Data? {
        return data(forKey: key)
    }
    
    /// Sets an array value for the specified key
    func setArray<T>(_ value: [T]?, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets an array value for the specified key
    func array<T>(for key: String, type: T.Type) -> [T]? {
        return array(forKey: key) as? [T]
    }
    
    /// Sets a dictionary value for the specified key
    func setDictionary<K, V>(_ value: [K: V]?, for key: String) {
        set(value, forKey: key)
    }
    
    /// Gets a dictionary value for the specified key
    func dictionary<K, V>(for key: String, keyType: K.Type, valueType: V.Type) -> [K: V]? {
        return dictionary(forKey: key) as? [K: V]
    }
    
    // MARK: - Codable Support
    
    /// Sets a Codable object for the specified key
    /// - Parameters:
    ///   - object: The Codable object to store
    ///   - key: The key to associate with the object
    func setCodable<T: Codable>(_ object: T?, for key: String) {
        guard let object = object else {
            removeObject(forKey: key)
            return
        }
        
        do {
            let data = try JSONEncoder().encode(object)
            set(data, forKey: key)
        } catch {
            print("Failed to encode object for key '\(key)': \(error)")
        }
    }
    
    /// Gets a Codable object for the specified key
    /// - Parameters:
    ///   - key: The key to retrieve the object for
    ///   - type: The type of the Codable object
    /// - Returns: The decoded object or nil if it doesn't exist or can't be decoded
    func codable<T: Codable>(for key: String, type: T.Type) -> T? {
        guard let data = data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode object for key '\(key)': \(error)")
            return nil
        }
    }
    
    // MARK: - Utility Methods
    
    /// Checks if a key exists in UserDefaults
    /// - Parameter key: The key to check
    /// - Returns: true if the key exists, false otherwise
    func exists(key: String) -> Bool {
        return object(forKey: key) != nil
    }
    
    /// Removes a value for the specified key
    /// - Parameter key: The key to remove
    func remove(key: String) {
        removeObject(forKey: key)
    }
    
    /// Removes multiple values for the specified keys
    /// - Parameter keys: The keys to remove
    func remove(keys: [String]) {
        keys.forEach { removeObject(forKey: $0) }
    }
}
