// ios/Runner/LiquidGlassTabBarFactory.swift
// Platform View Factory for Liquid Glass Tab Bar

import Flutter
import SwiftUI
import UIKit

// MARK: - Platform View Factory
class LiquidGlassTabBarFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return LiquidGlassTabBarPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args as? [String: Any],
            messenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - Platform View
class LiquidGlassTabBarPlatformView: NSObject, FlutterPlatformView {
    private var hostingController: UIHostingController<AnyView>?
    private let containerView: UIView
    private let channel: FlutterMethodChannel
    private var selectedIndex: Int = 0
    private var tabs: [TabItem] = []
    private var isDarkMode: Bool = false
    private var selectedColorHex: String = "586AAF" // AppColors.primary
    private var unselectedColorHex: String = "7896B6" // AppColors.textSecondary
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: [String: Any]?,
        messenger: FlutterBinaryMessenger
    ) {
        containerView = UIView(frame: frame)
        containerView.backgroundColor = .clear
        containerView.isOpaque = false
        
        channel = FlutterMethodChannel(
            name: "com.cleanslate/liquid_glass_tab_bar_\(viewId)",
            binaryMessenger: messenger
        )
        
        super.init()
        
        // Parse initial arguments
        if let args = args {
            parseArguments(args)
        }
        
        setupMethodChannel()
        setupSwiftUIView()
    }
    
    func view() -> UIView {
        return containerView
    }
    
    private func parseArguments(_ args: [String: Any]) {
        if let tabsData = args["tabs"] as? [[String: Any]] {
            tabs = tabsData.enumerated().map { index, data in
                TabItem(
                    id: index,
                    icon: data["icon"] as? String ?? "circle",
                    label: data["label"] as? String ?? "",
                    badgeCount: data["badge"] as? Int ?? 0
                )
            }
        }
        
        if let index = args["selectedIndex"] as? Int {
            selectedIndex = index
        }
        
        if let darkMode = args["isDarkMode"] as? Bool {
            isDarkMode = darkMode
        }
        
        if let selectedHex = args["selectedColorHex"] as? String {
            selectedColorHex = selectedHex
        }
        
        if let unselectedHex = args["unselectedColorHex"] as? String {
            unselectedColorHex = unselectedHex
        }
    }
    
    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            
            switch call.method {
            case "selectTab":
                if let args = call.arguments as? [String: Any],
                   let index = args["index"] as? Int {
                    self.selectedIndex = index
                    self.updateSwiftUIView()
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing index", details: nil))
                }
                
            case "updateBadge":
                if let args = call.arguments as? [String: Any],
                   let index = args["index"] as? Int,
                   let count = args["count"] as? Int {
                    if index < self.tabs.count {
                        self.tabs[index].badgeCount = count
                        self.updateSwiftUIView()
                    }
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing index or count", details: nil))
                }
                
            case "updateTabs":
                if let args = call.arguments as? [String: Any],
                   let tabsData = args["tabs"] as? [[String: Any]] {
                    self.tabs = tabsData.enumerated().map { index, data in
                        TabItem(
                            id: index,
                            icon: data["icon"] as? String ?? "circle",
                            label: data["label"] as? String ?? "",
                            badgeCount: data["badge"] as? Int ?? 0
                        )
                    }
                    self.updateSwiftUIView()
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing tabs", details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func setupSwiftUIView() {
        updateSwiftUIView()
    }
    
    private func updateSwiftUIView() {
        // Remove existing hosting controller
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        
        // Create colors from hex
        let selectedColor = Color(hex: selectedColorHex)
        let unselectedColor = Color(hex: unselectedColorHex)
        
        // Create SwiftUI view based on iOS version
        let swiftUIView: AnyView
        
        if #available(iOS 26.0, *) {
            swiftUIView = AnyView(
                LiquidGlassTabBarView(
                    selectedIndex: Binding(
                        get: { self.selectedIndex },
                        set: { self.selectedIndex = $0 }
                    ),
                    tabs: tabs,
                    isDarkMode: isDarkMode,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTabSelected: { [weak self] index in
                        self?.notifyFlutter(tabIndex: index)
                    }
                )
            )
        } else {
            swiftUIView = AnyView(
                FallbackTabBarView(
                    selectedIndex: Binding(
                        get: { self.selectedIndex },
                        set: { self.selectedIndex = $0 }
                    ),
                    tabs: tabs,
                    isDarkMode: isDarkMode,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTabSelected: { [weak self] index in
                        self?.notifyFlutter(tabIndex: index)
                    }
                )
            )
        }
        
        // Create and add hosting controller
        hostingController = UIHostingController(rootView: swiftUIView)
        hostingController?.view.backgroundColor = .clear
        hostingController?.view.isOpaque = false
        
        if let hostingView = hostingController?.view {
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(hostingView)
            
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
    }
    
    private func notifyFlutter(tabIndex: Int) {
        channel.invokeMethod("onTabSelected", arguments: ["index": tabIndex])
    }
}
