//
//  CalendarPane.swift
//  Island
//
//  Created by Ahmed Gaafar on 10/10/2026.
//

import SwiftUI
import Combine

struct CalendarPane: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private let dayHeaders = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(monthLabel)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            
            HStack(spacing: 0) {
                ForEach(Array(dayHeaders.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                    dayCell(date)
                }
            }
        }
        .onReceive(timer) { now = $0 }
    }
    
    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let date {
            let isToday = Calendar.current.isDateInToday(date)
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .black : .white.opacity(0.85))
                .frame(maxWidth: .infinity, minHeight: 16)
                .background(
                    isToday
                    ? RoundedRectangle(cornerRadius: 4).fill(Color.white)
                    : nil
                )
        } else {
            Color.clear.frame(height: 16)
        }
    }
    
    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: now)
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: now),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = firstWeekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        return days
    }
}
