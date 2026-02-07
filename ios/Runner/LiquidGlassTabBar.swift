// ios/Runner/LiquidGlassTabBar.swift
// Native SwiftUI Liquid Glass Tab Bar for iOS 26+
// With sliding bubble animation and icon animations

import SwiftUI
import Flutter

// MARK: - Tab Item Model
struct TabItem: Identifiable {
    let id: Int
    let icon: String
    let label: String
    var badgeCount: Int = 0
}

// MARK: - Liquid Glass Tab Bar View
@available(iOS 26.0, *)
struct LiquidGlassTabBarView: View {
    @Binding var selectedIndex: Int
    let tabs: [TabItem]
    let isDarkMode: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let onTabSelected: (Int) -> Void
    
    // Namespace for matched geometry effect
    @Namespace private var animation
    
    var body: some View {
        GeometryReader { geometry in
            let tabWidth = (geometry.size.width - 32) / CGFloat(tabs.count)
            
            ZStack {
                // Sliding bubble indicator
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: tabWidth * CGFloat(selectedIndex))
                    
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(width: tabWidth - 8, height: 52)
                        .glassEffect()
                    
                    Spacer()
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedIndex)
                
                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        AnimatedTabButton(
                            tab: tab,
                            isSelected: selectedIndex == tab.id,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                            action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedIndex = tab.id
                                }
                                onTabSelected(tab.id)
                            }
                        )
                        .frame(width: tabWidth)
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .glassEffect() // iOS 26 Liquid Glass modifier
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Animated Tab Button
@available(iOS 26.0, *)
struct AnimatedTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Trigger press animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? selectedColor : unselectedColor)
                        .scaleEffect(isSelected ? 1.1 : (isPressed ? 0.85 : 1.0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
                    
                    // Badge
                    if tab.badgeCount > 0 {
                        Text(tab.badgeCount > 99 ? "99+" : "\(tab.badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 10, y: -5)
                    }
                }
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? selectedColor : unselectedColor)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fallback for older iOS versions (with animations)
struct FallbackTabBarView: View {
    @Binding var selectedIndex: Int
    let tabs: [TabItem]
    let isDarkMode: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let onTabSelected: (Int) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let tabWidth = (geometry.size.width - 32) / CGFloat(tabs.count)
            
            ZStack {
                // Sliding bubble indicator
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: tabWidth * CGFloat(selectedIndex))
                    
                    Capsule()
                        .fill(isDarkMode ? Color.white.opacity(0.15) : Color.white.opacity(0.8))
                        .frame(width: tabWidth - 8, height: 52)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedIndex)
                
                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        FallbackAnimatedTabButton(
                            tab: tab,
                            isSelected: selectedIndex == tab.id,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                            action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedIndex = tab.id
                                }
                                onTabSelected(tab.id)
                            }
                        )
                        .frame(width: tabWidth)
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(isDarkMode ? .ultraThinMaterial : .regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Fallback Animated Tab Button
struct FallbackAnimatedTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? selectedColor : unselectedColor)
                        .scaleEffect(isSelected ? 1.1 : (isPressed ? 0.85 : 1.0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
                    
                    // Badge
                    if tab.badgeCount > 0 {
                        Text(tab.badgeCount > 99 ? "99+" : "\(tab.badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 10, y: -5)
                    }
                }
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? selectedColor : unselectedColor)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
