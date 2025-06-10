import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    private let selectedBoardStyleKey = "selectedBoardStyle"
    
    private init() {}
    
    func saveSelectedBoardStyle(_ style: Int) {
        defaults.set(style, forKey: selectedBoardStyleKey)
    }
    
    func getSelectedBoardStyle() -> Int {
        return defaults.integer(forKey: selectedBoardStyleKey)
    }
} 