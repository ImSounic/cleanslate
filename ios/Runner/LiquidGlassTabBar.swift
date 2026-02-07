// ios/Runner/LiquidGlassTabBar.swift
// Native SwiftUI Liquid Glass Tab Bar for iOS 26+

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
    let onTabSelected: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedIndex == tab.id,
                    action: {
                        selectedIndex = tab.id
                        onTabSelected(tab.id)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect() // iOS 26 Liquid Glass modifier
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

// MARK: - Tab Button
@available(iOS 26.0, *)
struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                    
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
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fallback for older iOS versions
struct FallbackTabBarView: View {
    @Binding var selectedIndex: Int
    let tabs: [TabItem]
    let onTabSelected: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button(action: {
                    selectedIndex = tab.id
                    onTabSelected(tab.id)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedIndex == tab.id ? Color(hex: "463C33") : .gray)
                        
                        Text(tab.label)
                            .font(.system(size: 10))
                            .foregroundColor(selectedIndex == tab.id ? Color(hex: "463C33") : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
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
