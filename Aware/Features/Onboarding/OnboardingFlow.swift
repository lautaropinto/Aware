//
//  OnboardingFlow.swift
//  Aware
//
//  Created by Lautaro Pinto on 9/11/25.
//

import SwiftUI
import SwiftData
import AwareData

struct OnboardingFlow: View {
    @AppStorage("aware-onboarding-ftu-completed") private var onboardingCompleted = false
    
    @Query private var tags: [Tag]
    
    @State private var step: Step = .one
    @State private var slowlyFade = false
    @State private var isCloudKitImporting = false
    @State private var allowSkip = false
    
    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if allowSkip {
                        Button("Skip") {
                            finishOnboarding()
                        }
                    }
                }
            }
            .applyBackgroundGradient()
            .cloudKitImporting($isCloudKitImporting)
        }
        .onChange(of: isCloudKitImporting) { _, newValue in
            if !newValue {
                withAnimation { allowSkip = !tags.isEmpty }
            }
        }
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
