//
//  ContentView.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ProductViewModel()

    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            PreferenceView(viewModel: viewModel)
                .tabItem {
                    Label("Preferensi", systemImage: "heart")
                }
        }
    }
}

#Preview {
    ContentView()
}

