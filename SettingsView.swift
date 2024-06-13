import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultTipPercentage") private var defaultTipPercentage = 15
    @AppStorage("defaultNumberOfPeople") private var defaultNumberOfPeople = 2
    @AppStorage("defaultCurrency") private var defaultCurrency = "USD"
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    let currencySymbols = ["USD", "EUR", "GBP"]
    
    var body: some View {
        VStack{
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Appearance Mode", selection: $appearanceMode) {
                        Text("Light").tag(AppearanceMode.light)
                        Text("Dark").tag(AppearanceMode.dark)
                        Text("System").tag(AppearanceMode.system)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section(header: Text("Default Tip Percentage")) {
                    Slider(value: Binding<Double>(
                        get: { Double(defaultTipPercentage) },
                        set: { defaultTipPercentage = Int($0) }
                    ), in: 0...50, step: 1)
                    
                    Text("\(defaultTipPercentage)%")
                }
                
                Section(header: Text("Default Number of People")) {
                    Stepper(value: $defaultNumberOfPeople, in: 1...50) {
                        Text("\(defaultNumberOfPeople)")
                    }
                }
                
                Section(header: Text("Default Currency")) {
                    Picker("Currency", selection: $defaultCurrency) {
                        ForEach(currencySymbols, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .navigationBarTitle("Settings")
        
        Spacer()
        
        HStack {
            Spacer()
            Text("Made with")
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
            Text("by Kevin Clear")
            Spacer()
        }
        .padding(.bottom)
    }
}
        enum AppearanceMode: String, CaseIterable {
            case light, dark, system
        }
