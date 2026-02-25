//
//  BallSpeedView.swift
//  Spare Time
//
//  Created by Aidan McKenzie on 2/22/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BallSpeedView: View {
    let frameNumber: Int
    @Binding var ballSpeed: Int?
    var onContinue: () -> Void
    var onSkip: () -> Void
    var onBack: () -> Void

    @State private var selected: Int = 13

    var body: some View {
        VStack(spacing: 0) {
            #if canImport(UIKit)
            Color.clear.frame(height: 0)
                .background { SwipeBackDisabler() }
            #endif
            Text("Frame \(frameNumber)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.primary)
                .padding(.top, 20)

            Spacer()

            Text("What speed\ndid you throw\nyour first ball?")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.primary)
                .multilineTextAlignment(.center)

            Spacer()

            SpeedWheelPicker(selection: $selected, range: 0...25)
                .frame(height: 260)

            Spacer()

            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.primary)
                }
                .padding(.leading, 28)

                Spacer()

                Button {
                    onSkip()
                } label: {
                    Text("Skip this step")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.secondary)
                }

                Button {
                    ballSpeed = selected
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.primary.opacity(0.9))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.surface)
                        )
                }
                .padding(.trailing, 28)
            }
            .padding(.bottom, 36)
        }
    }
}

// MARK: - Custom Wheel Picker

private struct SpeedWheelPicker: View {
    @Binding var selection: Int
    let range: ClosedRange<Int>

    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging = false
    private let itemHeight: CGFloat = 52
    private let visibleCount = 5

    private var centerIndex: CGFloat {
        -scrollOffset / itemHeight
    }

    var body: some View {
        ZStack {
            // Scrollable numbers
            GeometryReader { geo in
                let centerY = geo.size.height / 2
                ZStack {
                    ForEach(range, id: \.self) { value in
                        let floatOffset = CGFloat(value) * itemHeight + scrollOffset
                        let distFromCenter = floatOffset / itemHeight
                        let absDist = abs(distFromCenter)

                        if absDist < 3 {
                            numberLabel(value: value, distance: distFromCenter)
                                .position(x: geo.size.width / 2 - 28, y: centerY + floatOffset)
                        }
                    }
                }
            }
            .clipped()

            // Fixed "mph" label
            Text("mph")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Theme.primary)
                .offset(x: 38)

        }
        .frame(maxWidth: .infinity, maxHeight: itemHeight * CGFloat(visibleCount))
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    let proposed = -CGFloat(selection) * itemHeight + value.translation.height
                    let minOffset = -CGFloat(range.upperBound) * itemHeight
                    let maxOffset = -CGFloat(range.lowerBound) * itemHeight
                    // Rubber-band at edges
                    if proposed > maxOffset {
                        scrollOffset = maxOffset + (proposed - maxOffset) * 0.3
                    } else if proposed < minOffset {
                        scrollOffset = minOffset + (proposed - minOffset) * 0.3
                    } else {
                        scrollOffset = proposed
                    }
                }
                .onEnded { value in
                    isDragging = false
                    let projected = scrollOffset + value.predictedEndTranslation.height * 0.4 - value.translation.height * 0.4
                    let snappedIndex = -round(projected / itemHeight)
                    let clamped = Int(min(CGFloat(range.upperBound), max(CGFloat(range.lowerBound), snappedIndex)))
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selection = clamped
                        scrollOffset = -CGFloat(clamped) * itemHeight
                    }
                }
        )
        .onAppear {
            scrollOffset = -CGFloat(selection) * itemHeight
        }
        .onChange(of: selection) { _, newValue in
            if !isDragging {
                scrollOffset = -CGFloat(newValue) * itemHeight
            }
        }
    }

    private func numberLabel(value: Int, distance: CGFloat) -> some View {
        let absDist = min(abs(distance), 2.5)
        let fontSize: CGFloat = lerp(from: 44, to: 22, t: min(absDist, 1.0))
        let weight: Font.Weight = absDist < 0.5 ? .bold : .medium
        let opacity: Double = lerp(from: 1.0, to: 0.25, t: min(absDist / 2.0, 1.0))

        return Text("\(value)")
            .font(.system(size: fontSize, weight: weight))
            .foregroundStyle(Theme.primary.opacity(opacity))
    }

    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

// MARK: - Swipe-back suppressor

#if canImport(UIKit)
private struct SwipeBackDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    static func dismantleUIViewController(_ vc: UIViewController, coordinator: ()) {
        vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}
#endif

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        BallSpeedView(
            frameNumber: 1,
            ballSpeed: .constant(nil),
            onContinue: {},
            onSkip: {},
            onBack: {}
        )
    }
}
