import AudioToolbox

enum SoundManager {
    enum Sound: String {
        case success = "success"
        case milestone = "milestone"
        case streakBreak = "streak_break"
        case save = "save"
        case delete = "delete"
        case celebration = "celebration"
        case error = "error"
        case tap = "tap"
        case freeze = "freeze"
        case complete = "complete"
        case levelUp = "level_up"
    }

    static func play(_ sound: Sound) {
        switch sound {
        case .success:
            AudioServicesPlaySystemSound(1025) // subtle positive chime
        case .milestone:
            AudioServicesPlaySystemSound(1026) // celebration sound
        case .streakBreak:
            AudioServicesPlaySystemSound(1053) // gentle alert
        case .save:
            AudioServicesPlaySystemSound(1001) // mail sent swoosh
        case .delete:
            AudioServicesPlaySystemSound(1155) // trash sound
        case .celebration:
            AudioServicesPlaySystemSound(1026) // fanfare
        case .error:
            AudioServicesPlaySystemSound(1073) // error tone
        case .tap:
            AudioServicesPlaySystemSound(1104) // key press tick
        case .freeze:
            AudioServicesPlaySystemSound(1057) // shield/lock sound
        case .complete:
            AudioServicesPlaySystemSound(1025) // completion chime
        case .levelUp:
            AudioServicesPlaySystemSound(1026) // level up fanfare
        }
    }

    static var isSoundEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    static func playIfEnabled(_ sound: Sound) {
        guard isSoundEnabled else { return }
        play(sound)
    }
}
