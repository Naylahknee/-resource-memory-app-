import SwiftUI
import WidgetKit

// Must match the App Group in Runner.entitlements and
// LockScreenWidget.entitlements.
private let appGroupId = "group.com.naylahknee.resourcememory"
private let taskFileName = "current_task.json"
private let focusDeepLink = "resourcememory://focus"

private struct CurrentTask: Decodable {
  let title: String
  let key: String
  let dueAtMs: Int64?
}

private struct TaskEntry: TimelineEntry {
  let date: Date
  let title: String?
  let dueAt: Date?
}

/// Always 24-hour military time, regardless of the phone's 12/24h setting.
private let militaryTimeFormat: DateFormatter = {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "HH:mm"
  return formatter
}()

private func militaryTimeString(from date: Date) -> String {
  militaryTimeFormat.string(from: date)
}

private struct TaskProvider: TimelineProvider {
  func placeholder(in context: Context) -> TaskEntry {
    TaskEntry(date: Date(), title: "Your next step", dueAt: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
    let task = readTask()
    completion(TaskEntry(
      date: Date(),
      title: task?.title ?? "Open NanyNany",
      dueAt: task?.dueAt
    ))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
    // The app asks WidgetKit to reload on every task change, so this entry
    // is normally replaced immediately. The hourly refresh is only a backstop.
    let task = readTask()
    let entry = TaskEntry(date: Date(), title: task?.title, dueAt: task?.dueAt)
    let nextRefresh = Calendar.current.date(byAdding: .hour, to: Date())
      ?? Date().addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }

  private func readTask() -> (title: String, dueAt: Date?)? {
    guard
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupId
      )?
      .appendingPathComponent(taskFileName),
      let data = try? Data(contentsOf: container),
      let task = try? JSONDecoder().decode(CurrentTask.self, from: data),
      !task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return nil
    }
    let dueAt = task.dueAtMs.map { Date(timeIntervalSince1970: Double($0) / 1000.0) }
    return (task.title, dueAt)
  }
}

private struct LockScreenWidgetView: View {
  var entry: TaskProvider.Entry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryInline:
      Text(entry.title ?? "NanyNany")
        .widgetURL(URL(string: focusDeepLink))
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        Text(shortTitle)
          .font(.system(size: 11, weight: .semibold))
      }
      .widgetURL(URL(string: focusDeepLink))
    default:
      VStack(alignment: .leading, spacing: 2) {
        HStack {
          Text("START HERE")
            .font(.system(size: 10, weight: .bold))
          Spacer()
          if let dueAt = entry.dueAt {
            Text(militaryTimeString(from: dueAt))
              .font(.system(size: 12, weight: .semibold))
          }
        }
        Text(entry.title ?? "Nothing due. Enjoy the calm.")
          .font(.system(size: 14, weight: .semibold))
          .lineLimit(2)
      }
      .widgetURL(URL(string: focusDeepLink))
    }
  }

  private var shortTitle: String {
    guard let title = entry.title else { return "NanyNany" }
    let words = title.split(separator: " ")
    return words.prefix(2).joined(separator: " ")
  }
}

struct LockScreenWidget: Widget {
  let kind = "com.naylahknee.nanynany.LockScreenWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
      LockScreenWidgetView(entry: entry)
    }
    .configurationDisplayName("NanyNany: Start here")
    .description("Your one current task, right on the lock screen.")
    .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
  }
}
