import Foundation

struct StatusMenuActionDispatcher {
    private let schedule: (@escaping () -> Void) -> Void

    init(schedule: @escaping (@escaping () -> Void) -> Void = { action in
        DispatchQueue.main.async(execute: action)
    }) {
        self.schedule = schedule
    }

    func dispatch(_ action: @escaping () -> Void) {
        schedule(action)
    }
}
