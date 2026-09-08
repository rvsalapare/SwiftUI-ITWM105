import SwiftUI

struct ReportProblemLink: View {
    @EnvironmentObject var supabase: SupabaseManager
    let userId: UUID
    @State private var user: AppUser?

    var body: some View {
        Group {
            if let user {
                ReportUserSheet(userToReport: user)
            } else {
                ProgressView().task { user = try? await supabase.fetchUser(id: userId) }
            }
        }
    }
}
