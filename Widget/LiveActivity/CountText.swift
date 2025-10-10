//
//  CountText.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/27/25.
//

import SwiftUI

struct CountText: View {
    let timeInterval: ClosedRange<Date>
    
    var body: some View {
        Text("0:00:00")
            .hidden()
            .overlay {
                Text(timerInterval: timeInterval, countsDown: false)
                    .contentTransition(.numericText())
                    .fontDesign(.monospaced)
                    .multilineTextAlignment(.center)
            }
    }
}
