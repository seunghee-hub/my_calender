import SwiftUI
import SwiftData

struct MonthCalendarView: View {
    @Binding var month: Date
    @Binding var selectedDate: Date

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(DateTools.month(month))
                    .font(.title2.bold())
                Spacer()
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 36, height: 36)
                }
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            HStack(spacing: 0) {
                ForEach(Array(DateTools.weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(weekdayColor(column: index) ?? .secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            MonthGrid(month: month, selectedDate: $selectedDate) { tapped in
                selectedDate = tapped
                if !Calendar.current.isDate(tapped, equalTo: month, toGranularity: .month) {
                    month = DateTools.startOfMonth(tapped)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -50 { changeMonth(by: 1) }
                        if value.translation.width > 50 { changeMonth(by: -1) }
                    }
            )
        }
    }

    private func changeMonth(by n: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            month = DateTools.addMonths(n, to: month)
        }
    }

    /// 일요일 빨강, 토요일 파랑.
    private func weekdayColor(column: Int) -> Color? {
        let weekday = (Calendar.current.firstWeekday - 1 + column) % 7 + 1
        return weekday == 1 ? .red : weekday == 7 ? .blue : nil
    }
}

/// 한 달 날짜 칸 + 일정 점. 달이 바뀌면 그 달 일정만 다시 불러온다.
private struct MonthGrid: View {
    let month: Date
    @Binding var selectedDate: Date
    let onTap: (Date) -> Void

    @Query private var events: [CalendarEvent]
    private let days: [Date]

    init(month: Date, selectedDate: Binding<Date>, onTap: @escaping (Date) -> Void) {
        self.month = month
        self._selectedDate = selectedDate
        self.onTap = onTap
        let days = DateTools.monthGrid(for: month)
        self.days = days
        let gridStart = days.first ?? month
        let gridEnd = DateTools.addDays(1, to: days.last ?? month)
        _events = Query(
            filter: #Predicate<CalendarEvent> { event in
                event.startDate < gridEnd && event.endDate > gridStart
            },
            sort: \CalendarEvent.startDate
        )
    }

    var body: some View {
        let dots = colorsByDay
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
            ForEach(days, id: \.self) { day in
                DayCell(
                    day: day,
                    inMonth: Calendar.current.isDate(day, equalTo: month, toGranularity: .month),
                    isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                    isToday: Calendar.current.isDateInToday(day),
                    dots: dots[day] ?? []
                )
                .contentShape(Rectangle())
                .onTapGesture { onTap(day) }
            }
        }
    }

    /// 날짜(자정) → 그날 걸친 일정 색들.
    private var colorsByDay: [Date: [Color]] {
        let cal = Calendar.current
        var result: [Date: [Color]] = [:]
        for event in events {
            var day = cal.startOfDay(for: event.startDate)
            let lastMoment = event.endDate > event.startDate ? event.endDate.addingTimeInterval(-1) : event.startDate
            let lastDay = cal.startOfDay(for: lastMoment)
            var guardCount = 0
            while day <= lastDay && guardCount < 62 {
                result[day, default: []].append(event.color)
                day = DateTools.addDays(1, to: day)
                guardCount += 1
            }
        }
        return result
    }
}

private struct DayCell: View {
    let day: Date
    let inMonth: Bool
    let isSelected: Bool
    let isToday: Bool
    let dots: [Color]

    var body: some View {
        VStack(spacing: 3) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.callout.weight(isToday || isSelected ? .bold : .regular))
                .foregroundStyle(numberColor)
                .frame(width: 34, height: 34)
                .background {
                    if isSelected {
                        Circle().fill(Color.accentColor)
                    } else if isToday {
                        Circle().stroke(Color.accentColor, lineWidth: 1.5)
                    }
                }
            HStack(spacing: 3) {
                ForEach(Array(dots.prefix(3).enumerated()), id: \.offset) { _, color in
                    Circle().fill(color).frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .opacity(inMonth ? 1 : 0.35)
    }

    private var numberColor: Color {
        if isSelected { return .white }
        if isToday { return .accentColor }
        let weekday = Calendar.current.component(.weekday, from: day)
        if weekday == 1 { return .red }
        if weekday == 7 { return .blue }
        return .primary
    }
}
