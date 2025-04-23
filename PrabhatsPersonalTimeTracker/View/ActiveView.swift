import SwiftUI

struct ActiveView: View {
    @State private var showingCalendarEventSheet = false
    
    var body: some View {
        VStack {
            Text("Active Tasks")
                .font(.largeTitle)
            
            Button("Create Calendar Event") {
                showingCalendarEventSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(isPresented: $showingCalendarEventSheet) {
            CalendarEventView()
        }
    }
}

#Preview {
    ActiveView()
} 