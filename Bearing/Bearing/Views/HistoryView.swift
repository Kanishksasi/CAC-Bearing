import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var search = ""
    @State private var filterRaw = ""
    @Query private var settings: [UserSettings]

    private var visible: [Session] {
        sessions.filter { (filterRaw.isEmpty || $0.exerciseRaw == filterRaw)
            && (search.isEmpty || $0.displayTitle.localizedCaseInsensitiveContains(search)) }
    }
    var body: some View {
        Group {
            if sessions.isEmpty {
                BearingPage {
                    VStack(alignment: .leading, spacing: 20) {
                        Image(systemName: "clock").font(.system(size: 36, weight: .light))
                            .foregroundStyle(Color.accentColor).accessibilityHidden(true)
                        Text("No sessions yet.").font(.system(.largeTitle, design: .serif).weight(.medium))
                        Text("Your saved check-ins will appear here.").foregroundStyle(BearingStyle.muted)
                        NavigationLink {
                            SetupView(voiceEnabled: settings.first?.voiceEnabled ?? true)
                        } label: { Text("Start arm raise") }.buttonStyle(BearingPrimaryButton())
                    }.padding(.top, 32)
                }
            } else {
                List {
                    Section {
                        ForEach(visible) { session in
                            NavigationLink {
                                if session.isLegacy { LegacyResultView(session: session) }
                                else { ResultView(session: session) }
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(session.date.formatted(.dateTime.locale(Loc.locale).year().month(.abbreviated).day().hour().minute()))
                                        .font(.subheadline).foregroundStyle(BearingStyle.muted)
                                    ViewThatFits(in: .horizontal) {
                                        HStack {
                                            Text(session.isLegacy ? Loc.t("Earlier build session") : session.displayTitle + (session.exercise.isAngle ? ": " + session.exercise.sideTitle(session.side) : "")).font(.headline)
                                            Spacer(minLength: 16)
                                            if session.value != nil, !session.isLegacy { Text(session.valueText).font(.title3.weight(.semibold)) }
                                        }
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(session.isLegacy ? Loc.t("Earlier build session") : session.displayTitle + (session.exercise.isAngle ? ": " + session.exercise.sideTitle(session.side) : "")).font(.headline)
                                            if session.value != nil, !session.isLegacy { Text(session.valueText).font(.title3.weight(.semibold)) }
                                        }
                                    }
                                    if !session.isLegacy { Text(session.exercise.isManual ? Loc.t("Manual entry") : Strings.countedLine(session)).font(.subheadline).foregroundStyle(BearingStyle.muted) }
                                }.padding(.vertical, 10).frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }.buttonStyle(.automatic).accessibilityIdentifier("SavedSession").listRowBackground(BearingStyle.surface)
                        }
                    } header: { Text("Your saved sessions") }
                }
                .searchable(text: $search, prompt: "Find a check-in")
                .overlay { if visible.isEmpty { Text("No matching sessions.") } }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Routine", selection: $filterRaw) {
                                Text("All routines").tag("")
                                ForEach(Exercise.allCases) { Text($0.title).tag($0.rawValue) }
                            }
                        } label: { Label("Filter", systemImage: "line.3.horizontal.decrease.circle") }
                    }
                }.scrollContentBackground(.hidden).background(BearingStyle.paper).foregroundStyle(BearingStyle.ink)
            }
        }
        .navigationTitle("History").navigationBarTitleDisplayMode(.inline)
    }
}
