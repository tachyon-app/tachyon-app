import Foundation
import Cocoa

struct WindowInfo: Identifiable, Hashable {
    let id: CGWindowID            
    let ownerPID: pid_t           
    let appName: String           
    let title: String             
    let frame: CGRect             
    let layer: Int32              
    var appIcon: NSImage?         
    var snapshot: NSImage?        
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
        return lhs.id == rhs.id
    }
}
