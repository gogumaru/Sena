//
//  Product.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//

import Foundation

/// A single product as displayed inside the app.
///
/// Fields that are not always available on every Shopee listing are
/// optional, so a missing value is stored as `nil` instead of being
/// guessed at (per the experiment doc: "Jika data tidak tersedia, field
/// tersebut sebaiknya disimpan sebagai optional dan tidak diisi dengan
/// tebakan").
struct Product: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let price: Double?
    let rating: Double?
    let soldCount: Int?
    let seller: String?
    let url: String
    let imageURL: String?
}
