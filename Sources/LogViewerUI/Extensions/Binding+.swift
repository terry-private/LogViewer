import SwiftUI

extension Binding {
    func contains<T: Sendable>(_ element: T) -> Binding<Bool> where Value == Set<T> {
        Binding<Bool> (
            get: {
                wrappedValue.contains(element)
            },
            set: {
                if $0 {
                    wrappedValue.insert(element)
                } else {
                    wrappedValue.remove(element)
                }
            }
        )
    }
}
