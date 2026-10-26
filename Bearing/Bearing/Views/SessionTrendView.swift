import SwiftUI
import Charts

struct SessionTrendView: View {
    let session: Session
    let sessions: [Session]
    private var values: [Session] { TrendService.series(for: session, in: sessions) }
    var body: some View {
        if values.count >= 2 {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your history").font(.title3.bold())
                Chart(values) { record in
                    if let value = record.value {
                        LineMark(x: .value(Loc.t("Date"), record.date), y: .value(session.measurementTitle, value))
                            .foregroundStyle(Color.accentColor)
                        PointMark(x: .value(Loc.t("Date"), record.date), y: .value(session.measurementTitle, value))
                            .foregroundStyle(Color.accentColor)
                    }
                }.frame(height: 180).accessibilityLabel(Loc.t("Your recorded values over time"))
                Text("Only matching routines and sides are compared.").font(.footnote).foregroundStyle(BearingStyle.muted)
                ForEach(values.suffix(3)) { record in
                    Text(record.date.formatted(.dateTime.locale(Loc.locale).month().day()) + ": " + record.valueText)
                        .font(.callout)
                }
            }
        }
    }
}
