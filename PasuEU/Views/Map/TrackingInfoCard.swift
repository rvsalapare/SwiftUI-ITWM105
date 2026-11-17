import SwiftUI
import MapKit

struct TrackingInfoCard: View {
    let name: String
    let subtitle: String
    let distance: CLLocationDistance?
    let travelTime: TimeInterval?

    private var distanceText: String {
        guard let distance else { return "" }
        return MKDistanceFormatter().string(fromDistance: distance)
    }

    private var etaText: String {
        guard let travelTime else { return "Calculating arrival" }
        let minutes = max(1, Int((travelTime / 60).rounded()))
        let arrival = Date().addingTimeInterval(travelTime)
        return "\(minutes) min · \(arrival.formatted(date: .omitted, time: .shortened))"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white, Theme.brand)

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if distance == nil {
                Text("Waiting for \(name)'s location...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 150, alignment: .trailing)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(distanceText).font(.subheadline.bold()).foregroundStyle(Theme.brand)
                    Text(etaText).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
}

#Preview {
    TrackingInfoCard(name: "Mikha Lim", subtitle: "Errand Buddy", distance: 640, travelTime: 480)
        .padding()
}
