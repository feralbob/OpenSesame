//
//  HalfSheetModal.swift
//  ScrollToHide (iOS)
//
//  Created by Balaji on 08/07/21.
//
/// Support Balaji on Patreon https://www.patreon.com/posts/early-access-3-0-53427789?ref=morioh.com&utm_source=morioh.com
/// They make some really great tutorials


import SwiftUI

// Custom Half Sheet Modifier....
extension View{
    
    // Binding Show Variable...
    func halfSheet<SheetView: View>(showSheet: Binding<Bool>, supportsLargeView: Bool = true, @ViewBuilder sheetView: @escaping () -> SheetView, onEnd: (() -> ())? = nil) -> some View {
        
        // why we using overlay or background...
        // bcz it will automatically use the swiftui frame Size only....
        return self
            .background(
                HalfSheetHelper(sheetView: sheetView(), supportsLargeView: supportsLargeView, showSheet: showSheet, onEnd: onEnd ?? {})
            )
            .onChange(of: showSheet.wrappedValue) { newValue in
                if !newValue {
                    onEnd?()
                }
            }
    }
}

// UIKit Integration...
struct HalfSheetHelper<SheetView: View>: UIViewControllerRepresentable{
    
    var sheetView: SheetView
    var supportsLargeView: Bool = true
    @Binding var showSheet: Bool
    var onEnd: ()->()
    
    let controller = UIViewController()
    
    func makeCoordinator() -> Coordinator {
        
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
    
        controller.view.backgroundColor = .clear
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
     
        if showSheet{
            
            if uiViewController.presentedViewController == nil{
                
                // presenting Modal View....
                
                let sheetController = CustomHostingController(rootView: sheetView, supportsLargeView: supportsLargeView)
                sheetController.presentationController?.delegate = context.coordinator
                uiViewController.present(sheetController, animated: true)
            }
        }
        else{
            // closing view when showSheet toggled again...
            if uiViewController.presentedViewController != nil{
                uiViewController.dismiss(animated: true)
            }
        }
    }
    
    // On Dismiss...
    class Coordinator: NSObject,UISheetPresentationControllerDelegate{
        
        var parent: HalfSheetHelper
        
        init(parent: HalfSheetHelper, supportsLargeView: Bool = true) {
            self.parent = parent
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.showSheet = false
        }
    }
}

// Custom UIHostingController for halfSheet....
class CustomHostingController<Content: View>: UIHostingController<Content>{
    
    let supportsLargeView: Bool
    
    init(rootView: Content, supportsLargeView: Bool = false) {
        self.supportsLargeView = supportsLargeView
        
        super.init(rootView: rootView)
    }
    
    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
                
        // setting presentation controller properties...
        if let presentationController = presentationController as? UISheetPresentationController{
            
            presentationController.detents = supportsLargeView ? [
            
                .medium(),
                .large()
            ] : [.medium()]
            
            // to show grab protion...
            presentationController.prefersGrabberVisible = true
        }
    }
}
