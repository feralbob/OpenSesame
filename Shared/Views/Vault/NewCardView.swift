//
//  NewCardView.swift
//  NewCardView
//
//  Created by Ethan Lipnik on 8/29/21.
//

import SwiftUI

struct NewCardView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
    // MARK: - Variables
    @State private var name: String = ""
    @State private var holder: String = ""
    @State private var cardNumber: String = ""
    @State private var expirationDate: Date = Date()
    
    let selectedVault: Vault
    
    // MARK: - View
    var body: some View {
        VStack {
            VStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 30)
                VStack(alignment: .leading) {
                    TextField("Name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.title2)
                    TextField("Holder", text: $holder)
                        .textFieldStyle(.plain)
                        .font(.title2)
#if os(iOS)
                        .textContentType(.name)
                        .autocapitalization(.words)
#endif
                    Spacer()
                    HStack {
                        TextField("Card Number", text: $cardNumber)
                            .textFieldStyle(.plain)
                            .font(.system(.title2, design: .monospaced))
#if os(iOS)
                            .keyboardType(.numberPad)
                            .textContentType(.creditCardNumber)
#endif
                            .allowsTightening(true)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                        HStack(alignment: .bottom) {
                            Text("Valid Thru")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: [.date])
#if os(macOS)
                                .datePickerStyle(.field)
#endif
                                .font(.title3)
                                .labelsHidden()
                        }
                    }
                }
            }
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(colors: [Color("Tertiary"), Color("Tertiary").opacity(0.7)], startPoint: .top, endPoint: .bottom))
#if os(macOS)
                        .shadow(radius: 15, y: 8)
#else
                        .shadow(radius: 30, y: 8)
#endif
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(lineWidth: 2)
                        .fill(Color(white: 0.5, opacity: 0.25))
                }.compositingGroup()
            )
            .padding()
            .aspectRatio(1.6, contentMode: .fit)
#if os(macOS)
            .frame(height: 250)
#else
            .padding(.top)
#endif
#if os(iOS)
            Spacer()
#endif
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss.callAsFunction()
                }
                .keyboardShortcut(.cancelAction)
#if os(iOS)
                .hoverEffect()
#endif
                
                Spacer()
                
                Button("Add", action: add)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || holder.isEmpty || cardNumber.isEmpty || cardNumber.count < 15)
#if os(iOS)
                .hoverEffect()
#endif
            }.padding()
        }
#if os(macOS)
        .frame(width: 400)
#else
        .frame(maxWidth: 400)
#endif
    }
    
    // MARK: - Functions
    private func add() {
        do {
            let card = Card(context: viewContext)
            card.name = name
            card.holder = holder
            card.number = try CryptoSecurityService.encrypt(cardNumber)
            card.expirationDate = expirationDate
            
            selectedVault.addToCards(card)
            
            try viewContext.save()
            
            dismiss.callAsFunction()
        } catch {
            print(error)
        }
    }
}

struct NewCardView_Previews: PreviewProvider {
    static var previews: some View {
        NewCardView(selectedVault: .init())
    }
}
