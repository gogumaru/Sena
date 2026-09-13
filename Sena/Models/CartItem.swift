//
//  CartItem.swift
//  Sena
//
//  Created by Benedikta Anin on 11/09/26.
//


import Foundation

/// A single line item in the user's Shopee cart, used as a raw signal
/// for their shopping preference profile.
///
/// Price and quantity are optional: Shopee shows some cart items with
/// no price at all when the selected variant is out of stock (a
/// warning message shows instead), that's a real, common state, not a
/// scraping failure.
struct CartItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let variant: String?
    let price: Double?
    let quantity: Int?
    let url: String
    let imageURL: String?
    let isAvailable: Bool
}