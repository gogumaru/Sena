//
//  ShopeeLoginSheet.swift
//  Sena
//
//  Created by Benedikta Anin on 10/09/26.
//

import SwiftUI

struct ShopeeLoginSheet: View {
    @ObservedObject var viewModel: ProductViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isCookieImportPresented = false
    @State private var cookieHeaderInput = ""
    
    private static let entryURL = URL(string: "https://shopee.co.id")!
    
    var body: some View {
        NavigationStack {
            ShopeeWebView(url: Self.entryURL, coordinator: viewModel.loginCoordinator)
                .navigationTitle("Login Shopee")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Batal") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Selesai") {
                            viewModel.markShopeeConnected()
                            dismiss()
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button("Import cookie manual") {
                        isCookieImportPresented = true
                    }
                    .font(.footnote)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                }
                .alert("Paste Cookie Header", isPresented: $isCookieImportPresented) {
                    TextField("nama1=nilai1; nama2=nilai2; ...", text: $cookieHeaderInput)
                    Button("Import") {
                        viewModel.connectToShopee(cookieHeader: cookieHeaderInput)
                        dismiss()
                    }
                    Button("Batal", role: .cancel) {}
                } message: {
                    Text("Tempelkan cookie yang sudah di-copy di browser untukk login.")
                }
            }
        }
}
