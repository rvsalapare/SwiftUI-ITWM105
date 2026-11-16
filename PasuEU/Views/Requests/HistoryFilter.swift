import Foundation

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var id: String { rawValue }

    func includes(_ status: RequestStatus) -> Bool {
        switch self {
        case .all: return true
        case .active: return status == .pending || status == .accepted || status == .inProgress
        case .completed: return status == .completed
        case .cancelled: return status == .cancelled
        }
    }

    var emptyMessage: String {
        switch self {
        case .all: return "Requests you create will show up here once submitted."
        case .active: return "You have no pending or in-progress requests right now."
        case .completed: return "Completed requests will show up here."
        case .cancelled: return "You haven't cancelled any requests."
        }
    }
}
