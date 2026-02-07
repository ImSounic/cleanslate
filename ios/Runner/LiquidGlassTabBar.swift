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
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let tabWidth = totalWidth / CGFloat(tabs.count)
            
            ZStack {
                // Sliding bubble indicator
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: tabWidth * CGFloat(selectedIndex))
                    
                    Capsule()
                        .fill(isDarkMode ? Color.white.opacity(0.2) : Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .frame(width: tabWidth - 16, height: 50)
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedIndex)
                
                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        AnimatedTabButton(
                            tab: tab,
                            isSelected: selectedIndex == tab.id,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                            action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
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
        .frame(height: 64)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassEffect() // iOS 26 Liquid Glass modifier
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .padding(.horizontal, 16)
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
            VStack(spacing: 3) {
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
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            let totalWidth = geometry.size.width
            let tabWidth = totalWidth / CGFloat(tabs.count)
            
            ZStack {
                // Sliding bubble indicator
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: tabWidth * CGFloat(selectedIndex))
                    
                    Capsule()
                        .fill(isDarkMode ? Color.white.opacity(0.15) : Color.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(isDarkMode ? 0.2 : 0.08), radius: 6, x: 0, y: 2)
                        .frame(width: tabWidth - 16, height: 50)
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedIndex)
                
                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        FallbackAnimatedTabButton(
                            tab: tab,
                            isSelected: selectedIndex == tab.id,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                            action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
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
        .frame(height: 64)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Group {
                if isDarkMode {
                    Color(red: 0.15, green: 0.15, blue: 0.18).opacity(0.85)
                } else {
                    Color(red: 0.96, green: 0.95, blue: 0.93).opacity(0.85)
                }
            }
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .padding(.horizontal, 16)
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
            VStack(spacing: 3) {
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
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
