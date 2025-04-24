import SwiftUI

struct MatchCard: View {
    let match: PremierMatch
    
    private var resultColor: Color {
        match.result == "Victory" ? .green : .red
    }
    
    private var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(match.timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with map and result
            HStack {
                Text(match.map)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(match.result)
                    .font(.headline)
                    .foregroundColor(resultColor)
            }
            
            // Score and details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score: \(match.score)")
                        .foregroundColor(.white)
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("\(match.kills)-\(match.deaths)-\(match.assists)")
                    .foregroundColor(.white)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.white)
                .bold()
        }
    }
}

struct StatCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.white)
                .bold()
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(8)
        }
    }
} 