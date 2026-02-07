// ios/Runner/LiquidGlassTabBar.swift
// Native SwiftUI Tab Bar with Telegram-style sliding bubble animation

import SwiftUI
import Flutter

// MARK: - Tab Item Model
struct TabItem: Identifiable {
    let id: Int
    let icon: String           // SF Symbol name (outline version)
    let iconFilled: String     // SF Symbol name (filled version)
    let label: String
    var badgeCount: Int = 0
    
    // Convenience initializer that auto-generates filled icon name
    init(id: Int, icon: String, label: String, badgeCount: Int = 0) {
        self.id = id
        self.icon = icon
        // Most SF Symbols have .fill variant
        self.iconFilled = icon.contains(".fill") ? icon : icon + ".fill"
        self.label = label
        self.badgeCount = badgeCount
    }
}

// MARK: - Telegram-Style Tab Bar View (iOS 26+)
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
            let bubbleSize: CGFloat = 56
            
            ZStack {
                // Sliding white bubble indicator
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: (tabWidth * CGFloat(selectedIndex)) + (tabWidth - bubbleSize) / 2)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: bubbleSize, height: bubbleSize)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    
                    Spacer()
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedIndex)
                
                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        TelegramTabButton(
                            tab: tab,
                            isSelected: selectedIndex == tab.id,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                            action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
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
        .frame(height: 70)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Telegram Tab Button (iOS 26+)
@available(iOS 26.0, *)
struct TelegramTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? selectedColor : unselectedColor)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    
                    // Badge
                    if tab.badgeCount > 0 {
                        Text(tab.badgeCount > 99 ? "99+" : "\(tab.badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 12, y: -6)
                    }
                }
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? selectedColor : unselectedColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fallback Tab Bar (pre-iOS 26)
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
            let bubbleSize: CGFloat = 56
            
            ZStack {
                // Sliding white bubble indicator
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: (tabWidth * CGFloat(selectedIndex)) + (tabWidth - bubbleSize) / 2)
                    
                    Circle()
                        .fill(isDarkMode ? Color.white.opacity(0.15) : Color.white)
                        .frame(width: bubbleSize, height: bubbleSize)
                        .shadow(color: Color.black.opacity(isDarkMode ? 0.2 : 0.08), radius: 8, x: 0, y: 2)
                    
                    Spacer()
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedIndex)
                
                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        FallbackTelegramTabButton(
                            tab: tab,
                            isSelected: selectedIndex == tab.id,
                            selectedColor: selectedColor,
                            unselectedColor: unselectedColor,
                            action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
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
        .frame(height: 70)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(isDarkMode 
                    ? Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.9)
                    : Color(red: 0.97, green: 0.97, blue: 0.97).opacity(0.9)
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 35)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Fallback Telegram Tab Button
struct FallbackTelegramTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? tab.iconFilled : tab.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? selectedColor : unselectedColor)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    
                    // Badge
                    if tab.badgeCount > 0 {
                        Text(tab.badgeCount > 99 ? "99+" : "\(tab.badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 12, y: -6)
                    }
                }
                
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? selectedColor : unselectedColor)
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
