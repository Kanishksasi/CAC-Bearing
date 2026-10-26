import SwiftUI

struct LegacyResultView: View {
    let session: Session
    var body: some View {
        BearingPage {
            VStack(alignment: .leading, spacing: 20) {
                Text("Earlier build session").font(.largeTitle.bold())
                Text(session.date.formatted(.dateTime.locale(Loc.locale).year().month(.abbreviated).day().hour().minute()))
                Text("These numbers used an earlier method. They do not set your new starting point.")
                if let value = session.leftBest { row("Left side best", value) }
                if let value = session.leftAverage { row("Left side average", value) }
                if let value = session.rightBest { row("Right side best", value) }
                if let value = session.rightAverage { row("Right side average", value) }
                if let count = session.standCount { Text(Loc.f("Recorded stands: %lld", count)) }
                if let seconds = session.holdSeconds { Text(Loc.f("Recorded hold: %.1f seconds", seconds)) }
                if let sway = session.swayRatio { Text(Loc.f("Recorded sway: %.2f of shoulder width", sway)) }
                Text(Strings.disclaimer).font(.footnote)
            }
        }.navigationTitle("History")
    }
    private func row(_ title: String, _ value: Double) -> some View {
        Text(Loc.t(title) + ": " + Strings.angle(value))
    }
}
