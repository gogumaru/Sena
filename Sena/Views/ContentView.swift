//
//  ContentView.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ProductViewModel()
    @State private var isLoginSheetPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12){
                    connectionSection

                    SearchView(viewModel: viewModel)
                }
                .padding(.top,8)

                if let url = viewModel.searchURL {
                    ShopeeWebView(url: url, coordinator: viewModel.coordinator)
                        .frame(width:0, height: 0)
                        .accessibilityHidden(true)
                }
                ProductListView(viewModel: viewModel)
            }
            .navigationTitle("Sena")
            .sheet(isPresented: $isLoginSheetPresented){
                ShopeeLoginSheet(viewModel: viewModel)
            }
        }
    }

    private var connectionSection: some View {
        HStack{
            Image(systemName: viewModel.isShopeeConnected ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(viewModel.isShopeeConnected ? .green : .secondary)
            Text(viewModel.isShopeeConnected ? "Terhubung ke Shopee" : "Belum terhubung ke Shopee")
                .font(.subheadline)
            Spacer()

            Button(viewModel.isShopeeConnected ? "Sambungkan Ulang" : "Hubungkan ke Shopee") {
                isLoginSheetPresented = true
            }
            .buttonStyle(.bordered)

            if viewModel.isShopeeConnected {
                Button("Putuskan", role: .destructive) {
                    viewModel.disconnectFromShopee()
                }
                .buttonStyle(.borderless)
            }

        }
        .padding()
    }
}


#Preview {
    ContentView()
}
