//
//  ColorfulIcon.swift
//  Aware
//
//  Created by Lautaro Pinto on 10/6/25.
//


import SwiftUI

struct ColorfulIcon: LabelStyle {
    var color: Color
    var size = 1.0
    var iconPadding: Bool = false
    
    private let baseSize: CGFloat = 28.0
    
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
                .foregroundStyle(Color.primary)
        } icon: {
            configuration.icon
                .imageScale(.small)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 7.0 * size)
                        .frame(
                            width: baseSize * size,
                            height: baseSize * size
                        ).foregroundColor(color)
                )
                .padding(.trailing, iconPadding ? 12.0 : 0.0)
        }
    }
}
