import SwiftUI
import SwiftData

struct RoutineLibraryView: View {
    @Query private var settings: [UserSettings]
    var body: some View {
        BearingPage {
            Text("Choose a routine").font(.largeTitle.bold())
            Text("Use movements you already know. Ask your clinician which routines are right for you.")
                .foregroundStyle(BearingStyle.muted)
            ForEach(Exercise.cameraRoutines) { exercise in
                NavigationLink {
                    SetupView(voiceEnabled: settings.first?.voiceEnabled ?? true, exercise: exercise,
                              helperMode: settings.first?.caregiverMode ?? false)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: exercise.symbol).font(.title2).frame(width: 36).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.title).font(.headline)
                            Text(exercise.isAngle ? Loc.t("Three attempts for one side") : (exercise == .balance ? Loc.t("Hold up to ten seconds") : Loc.f("Up to %lld seconds", Int(exercise.seconds))))
                                .font(.subheadline).foregroundStyle(BearingStyle.muted)
                            if exercise.needsSupport { Text("Support and someone nearby").font(.footnote) }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).accessibilityHidden(true)
                    }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                        .background(BearingStyle.surface, in: RoundedRectangle(cornerRadius: 20))
                }.buttonStyle(.plain).accessibilityLabel(exercise.title)
            }
            PrivacyNote()
        }.navigationTitle("All routines")
    }
}
