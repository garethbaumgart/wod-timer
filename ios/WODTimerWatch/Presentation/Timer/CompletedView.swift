import SwiftUI

/// End screen: one word, one line, one number. The number is the athlete's
/// score (AMRAP rounds, For Time time, how far a stopped workout got); a
/// natural EMOM / Tabata finish is just "Finished", a capped For Time
/// "Time cap". AMRAP rounds can be corrected with minus / plus.
struct CompletedView: View {
    @Bindable var viewModel: TimerViewModel

    private struct Score {
        let value: String
        let label: String
        var secondary: String?
        var adjustable = false
    }

    var body: some View {
        if let session = viewModel.session {
            VStack(spacing: 2) {
                if let score = score(session) {
                    Text(viewModel.endedEarly ? "Stopped" : "Finished")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(viewModel.endedEarly ? Palette.label : .white)
                    config(session)
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        if score.adjustable {
                            ghost("minus", label: "One round fewer", enabled: session.countedRounds > 0) {
                                viewModel.adjustRounds(by: -1)
                            }
                        }
                        Text(score.value)
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .foregroundStyle(viewModel.endedEarly ? .white : Palette.primary)
                            .frame(maxWidth: .infinity)
                        if score.adjustable {
                            ghost("plus", label: "One round more", enabled: true) {
                                viewModel.adjustRounds(by: 1)
                            }
                        }
                    }
                    Text(score.label)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Palette.label)
                    if let secondary = score.secondary {
                        Text("\(secondary) TIME")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                    Text(viewModel.endedAtTimeCap ? "Time cap" : "Finished")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(viewModel.endedAtTimeCap ? Palette.label : .white)
                    config(session)
                    Spacer(minLength: 0)
                }

                HStack(spacing: 6) {
                    endButton("AGAIN") { viewModel.restart() }
                    // DONE lands on this mode's setup (the timer was pushed
                    // from it), with the workout just run remembered.
                    endButton("DONE") { viewModel.reset() }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 10)
            .navigationBarBackButtonHidden(true)
        }
    }

    private func score(_ session: TimerSession) -> Score? {
        if viewModel.endedAtTimeCap { return nil }
        switch session.workout.timerType {
        case .amrap:
            return Score(
                value: "\(session.countedRounds)",
                label: "ROUNDS",
                secondary: viewModel.endedEarly ? session.elapsed.clock : nil,
                adjustable: true
            )
        case .forTime:
            return Score(value: session.elapsed.clock, label: "TIME")
        default:
            guard viewModel.endedEarly, let total = session.totalRounds else { return nil }
            return Score(value: "\(session.currentRound)/\(total)", label: "ROUNDS")
        }
    }

    private func config(_ session: TimerSession) -> some View {
        Text(LiveRules.configLine(session.workout.timerType))
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.label)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func ghost(_ icon: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(enabled ? 0.55 : 0.15))
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(.white.opacity(enabled ? 0.4 : 0.12), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func endButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 34)
                .foregroundStyle(.white)
                .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color(hex: 0x55555E), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CompletedView(viewModel: TimerViewModel())
}
