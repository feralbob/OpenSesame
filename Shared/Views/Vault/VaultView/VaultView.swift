//
//  VaultView.swift
//  VaultView
//
//  Created by Ethan Lipnik on 8/18/21.
//

import SwiftUI
import AuthenticationServices
import Foundation

struct VaultView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - CoreData Variables
    @FetchRequest var accounts: FetchedResults<Account>
    @FetchRequest var cards: FetchedResults<Card>
    
    // MARK: - Variables
    let vault: Vault
    
    @State var selectedAccount: Account? = nil
    @State var selectedCard: Card? = nil
    
    @State var shouldDeleteAccount: Bool = false
    @State var accountToBeDeleted: Account? = nil
    
    @State var isCreatingNewAccount: Bool = false
    @State var isCreatingNewCard: Bool = false
    
    @State var search: String = ""
    
    // MARK: - Init
    init(vault: Vault, selectedAccount: Account? = nil, selectedCard: Card? = nil) {
        self.vault = vault
        self._selectedAccount = .init(initialValue: selectedAccount)
        self._selectedCard = .init(initialValue: selectedCard)
        
        self._accounts = FetchRequest(sortDescriptors: [.init(key: "domain", ascending: true)],
                                      predicate: NSPredicate(format: "vault == %@", vault), animation: .default)
        self._cards = FetchRequest(sortDescriptors: [],
                                  predicate: NSPredicate(format: "vault == %@", vault), animation: .default)
    }
    
    // MARK: - View
    var body: some View {
        list
#if os(macOS)
        .sheet(isPresented: $isCreatingNewAccount) {
            NewAccountView(selectedVault: vault)
        }
        .sheet(isPresented: $isCreatingNewCard) {
            NewCardView(selectedVault: vault)
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .navigationTitle("OpenSesame – " + (vault.name ?? "Unknown vault"))
        .frame(minWidth: 200)
#else
        .halfSheet(showSheet: $isCreatingNewAccount) {
            NewAccountView(selectedVault: vault)
                .onDisappear {
                    isCreatingNewAccount = false
                }
        } onEnd: {
            isCreatingNewAccount = false
        }
        .halfSheet(showSheet: $isCreatingNewCard, supportsLargeView: false) {
            NewCardView(selectedVault: vault)
                .onDisappear {
                    isCreatingNewCard = false
                }
        } onEnd: {
            isCreatingNewCard = true
        }
        .listStyle(.insetGrouped)
        .navigationTitle(vault.name ?? "Vault")
#endif
        .searchable(text: $search)
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
#endif
            ToolbarItem {
                Menu {
                    Button {
                        isCreatingNewAccount.toggle()
                    } label: {
                        Label("Add Account", systemImage: "person")
                    }
                    Button {
                        isCreatingNewCard.toggle()
                    } label: {
                        Label("Add Card", systemImage: "creditcard")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .onOpenURL { url in
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let query = components.query, let url = components.string?.replacingOccurrences(of: "?" + query, with: ""), let queryItems = components.queryItems {
                if let type = queryItems.first(where: { $0.name == "type" }), url == "openSesame://new" {
                    switch type.value {
                    case "account":
                        isCreatingNewAccount = true
                    case "card":
                        isCreatingNewCard = true
                    default:
                        break
                    }
                }
            } else {
                print("Badly formatted URL")
            }
        }
    }
    
    func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { accounts[$0] }.forEach { account in
                
                let domainIdentifer = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: account.domain!, type: .domain),
                                                                   user: account.username!,
                                                                   recordIdentifier: nil)
                
                ASCredentialIdentityStore.shared.removeCredentialIdentities([domainIdentifer]) { success, error in
                    if let error = error {
                        print("Failed to remove credential", error)
                        
#if os(macOS)
                        NSAlert(error: NSError(domain: "Failed to delete credential for autofill: \(error.localizedDescription)", code: 0, userInfo: nil)).runModal()
#endif
                    }
                }
                
                viewContext.delete(account)
            }
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView(vault: .init())
    }
}
