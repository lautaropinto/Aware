//
//  OnboardingFlow.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI

struct OnboardingFlow: View {
    @AppStorage("aware-onboarding-ftu-completed") private var onboardingCompleted = false
    
    @State private var step: Step = .one
    @State private var slowlyFade = false
    
    var body: some View {
        VStack {
            switch step {
            case .one:
                OnboardingStepOne(onContinue: {
                    withAnimation { step = .two }
                })
            case .two:
                OnboardingStepTwo(onContinue: {
                    withAnimation { step = .final }
                })
            case .final:
                OnboardingStepThree(onContinue: {
                    finishOnboarding()
                })
                .opacity(slowlyFade ? 0.0 : 1.0)
            }
        }
        .applyBackgroundGradient()
    }
    
    private func finishOnboarding() {
        withAnimation(.spring(duration: 1.5)) {
            slowlyFade = true
        } completion: {
            onboardingCompleted = true
        }
    }
    
    enum Step {
        case one, two, final
    }
}

#Preview {
    OnboardingFlow()
}
