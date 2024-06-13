import SwiftUI
import PDFKit
import PassKit
import UIKit
import MessageUI

//class MessageComposeDelegate: NSObject, MFMessageComposeViewControllerDelegate {
//    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
//        controller.dismiss(animated: true)
//    }
//}

struct ContentView: View {
    @State private var billAmount = ""
    //@State private var messageComposer: MFMessageComposeViewController?
    //@State private var messageComposeDelegate: MessageComposeDelegate?
    @AppStorage("defaultTipPercentage") private var tipPercentage = 15
    @State private var customTipPercentage = ""
    @AppStorage("defaultNumberOfPeople") private var numberOfPeople = 2
    @AppStorage("defaultCurrency") private var selectedCurrency = "USD"
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    let tipPercentages = [15, 18, 20, 22, 0]
    let currencySymbols = ["USD": "$", "EUR": "€", "GBP": "£"]
    
    var totalAmount: Double {
        let billAmount = Double(billAmount) ?? 0
        let tipAmount = billAmount * Double(selectedTipPercentage) / 100
        return billAmount + tipAmount
    }
    
    var totalPerPerson: Double {
        let peopleCount = Double(numberOfPeople)
        let amountPerPerson = totalAmount / peopleCount
        return amountPerPerson
    }
    
    var selectedTipPercentage: Int {
        if tipPercentage == 0 {
            return Int(customTipPercentage) ?? 0
        }
        return tipPercentage
    }
    
    var currencySymbol: String {
        return currencySymbols[selectedCurrency] ?? "$"
    }
    
    var body: some View {
            NavigationView {
                VStack {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                            .padding(.leading, 10)
                        TextField("Bill Total", text: $billAmount)
                            .padding(.vertical)
                            .keyboardType(.decimalPad)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    VStack {
                        Picker("Tip Percentage", selection: $tipPercentage) {
                            ForEach(tipPercentages, id: \.self) {
                                Text("\($0)%")
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        if tipPercentage == 0 {
                            TextField("Custom Tip Percentage", text: $customTipPercentage)
                                .padding()
                                .keyboardType(.numberPad)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .overlay(
                                    Image(systemName: "percent")
                                        .foregroundColor(.gray)
                                        .frame(width: 30, height: 30, alignment: .trailing)
                                        .offset(x: -30, y: 0)
                                        .opacity(customTipPercentage.isEmpty ? 0 : 1)
                                    , alignment: .trailing
                                )
                        }
                    }
                    .frame(height: tipPercentage == 0 ? 100 : 50)

                    HStack {
                        Image(systemName: "person.2")
                        Spacer()
                        Stepper(value: $numberOfPeople, in: 1...50) {
                            Text("\(numberOfPeople)")
                        }
                    }
                    .padding()

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tip Amount:")
                            Spacer()
                            Text("\(currencySymbol)\(totalAmount - (Double(billAmount) ?? 0), specifier: "%.2f")")
                        }
                        HStack {
                            Text("Total Amount:")
                            Spacer()
                            Text("\(currencySymbol)\(totalAmount, specifier: "%.2f")")
                        }
                        HStack {
                            Text("Amount per Person:")
                            Spacer()
                            Text("\(currencySymbol)\(totalPerPerson, specifier: "%.2f")")
                        }
                    }
                    .padding()

                    Spacer()

                    HStack {
                        Button(action: {
                            shareReceipt()
                        }) {
                            Text("Share Receipt")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
//                            Button(action: {
//                                requestReimbursement()
//                            }) {
//                                Text("Send Message")
//                                    .foregroundColor(.white)
//                                    .padding()
//                                    .background(Color.green)
//                                    .cornerRadius(10)
//                            }
                        
                    }
                    .padding()
                }
                .navigationBarTitle("Tip Calculator")
                .navigationBarItems(trailing:
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                )
            }
            .preferredColorScheme(getColorScheme())
        }

        private func getColorScheme() -> ColorScheme? {
            switch appearanceMode {
            case .light:
                return .light
            case .dark:
                return .dark
            case .system:
                return nil
            }
        }

        private func shareReceipt() {
            let pdfData = generatePDFReceipt()
            let fileName = generatePDFReceiptFileName()
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            let fileURL = documentsDirectory.appendingPathComponent(fileName)

            do {
                try pdfData.write(to: fileURL)
                let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(activityViewController, animated: true, completion: nil)
                }
            } catch {
                print("Could not save or share PDF file: \(error.localizedDescription)")
            }
        }

//    private func requestReimbursement() {
//        guard MFMessageComposeViewController.canSendText() else {
//            print("Cannot send text messages from this device.")
//            return
//        }
//
//        let messageComposeVC = MFMessageComposeViewController()
//        let messageComposeDelegate = MessageComposeDelegate()
//        messageComposeVC.messageComposeDelegate = messageComposeDelegate
//        messageComposeVC.body = "Hey, can you reimburse me \(currencySymbol)\(totalAmount) for the recent bill?"
//        messageComposeVC.recipients = []
//
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let window = windowScene.windows.first,
//           let rootViewController = window.rootViewController {
//            rootViewController.present(messageComposeVC, animated: true, completion: nil)
//        }
//    }
    
    func generatePDFReceipt() -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Tip Calculator",
            kCGPDFContextAuthor: "Your Name",
            kCGPDFContextTitle: "Tip Calculator Receipt"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            let titleAttributes2 = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18),
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
            let titleText1 = "Tip Calculator"
            let titleText2 = "Receipt"
            
            let titleSize1 = titleText1.size(withAttributes: titleAttributes)
            let titleSize2 = titleText2.size(withAttributes: titleAttributes2)
            
            let titleRect1 = CGRect(x: (pageRect.width - titleSize1.width) / 2, y: 20, width: titleSize1.width, height: titleSize1.height)
            let titleRect2 = CGRect(x: (pageRect.width - titleSize2.width) / 2, y: titleRect1.maxY + 10, width: titleSize2.width, height: titleSize2.height)
            
            titleText1.draw(in: titleRect1, withAttributes: titleAttributes)
            titleText2.draw(in: titleRect2, withAttributes: titleAttributes2)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 10
            let contentAttributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ]
            
            let boldAttributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16),
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ]
            
            let billTotalText = NSMutableAttributedString(string: "Bill Total: ", attributes: boldAttributes)
                    billTotalText.append(NSAttributedString(string: "\(currencySymbol)\(String(format: "%.2f", Double(billAmount) ?? 0))\n", attributes: contentAttributes))
                    
                    let tipPercentageText = NSMutableAttributedString(string: "Tip Percentage: ", attributes: boldAttributes)
                    tipPercentageText.append(NSAttributedString(string: "\(selectedTipPercentage)%\n", attributes: contentAttributes))
                    
                    let tipAmountText = NSMutableAttributedString(string: "Tip Amount: ", attributes: boldAttributes)
                    tipAmountText.append(NSAttributedString(string: "\(currencySymbol)\(String(format: "%.2f", totalAmount - (Double(billAmount) ?? 0)))\n", attributes: contentAttributes))
                    
                    let totalAmountText = NSMutableAttributedString(string: "Total Amount: ", attributes: boldAttributes)
                    totalAmountText.append(NSAttributedString(string: "\(currencySymbol)\(String(format: "%.2f", totalAmount))\n", attributes: contentAttributes))
                    
                    let amountPerPersonText = NSMutableAttributedString(string: "Amount per Person: ", attributes: boldAttributes)
                    amountPerPersonText.append(NSAttributedString(string: "\(currencySymbol)\(String(format: "%.2f", totalPerPerson))\n", attributes: contentAttributes))
                    
                    let numberOfPeopleText = NSMutableAttributedString(string: "Number of People: ", attributes: boldAttributes)
                    numberOfPeopleText.append(NSAttributedString(string: "\(numberOfPeople)\n", attributes: contentAttributes))
                    
            
            let combinedText = NSMutableAttributedString()
            combinedText.append(billTotalText)
            combinedText.append(tipPercentageText)
            combinedText.append(tipAmountText)
            combinedText.append(totalAmountText)
            combinedText.append(numberOfPeopleText)
            combinedText.append(amountPerPersonText)
            
            let contentRect = CGRect(x: 40, y: titleRect2.maxY + 40, width: pageRect.width - 80, height: pageRect.height - titleRect2.maxY - 60)
            combinedText.draw(with: contentRect, options: .usesLineFragmentOrigin, context: nil)
            
            // Draw a line separator
            let separatorRect = CGRect(x: 40, y: contentRect.maxY + 10, width: pageRect.width - 80, height: 1)
            context.cgContext.setFillColor(UIColor.lightGray.cgColor)
            context.cgContext.fill(separatorRect)
        }
        
        return data
    }

    func savePDF(data: Data) {
        let fileName = generatePDFReceiptFileName()
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("PDF saved successfully: \(fileURL)")
        } catch {
            print("Could not save PDF file: \(error.localizedDescription)")
        }
    }

    func sharePDF(data: Data, from viewController: UIViewController) {
        let fileName = generatePDFReceiptFileName()
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            viewController.present(activityViewController, animated: true, completion: nil)
        } catch {
            print("Could not save or share PDF file: \(error.localizedDescription)")
        }
    }
    func generatePDFReceiptFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        return "Receipt_\(dateString).pdf"
    }

    // Usage Example:
    // let pdfData = generatePDFReceipt()
    // savePDF(data: pdfData)
    // sharePDF(data: pdfData, from: self)

    }
