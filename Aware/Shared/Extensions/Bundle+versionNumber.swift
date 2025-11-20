//
//  Bundle+versionNumber.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//


import Foundation

extension Bundle {
    private var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    private var buildVersionNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    
    static var versionNumber: String {
        "\(Bundle.main.releaseVersionNumber) (\(Bundle.main.buildVersionNumber))"
    }
}
