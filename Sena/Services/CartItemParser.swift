//
//  CartItemParser.swift
//  Sena
//
//  Created by Benedikta Anin on 11/09/26.
//


import Foundation

enum CartItemParser {

    private struct RawCartItem: Decodable {
        let id: String?
        let title: String?
        let variant: String?
        let rawPrice: String?
        let rawQuantity: String?
        let url: String?
        let imageURL: String?
    }

    enum ParseError: Error {
        case invalidJSON
    }

    static func parse(json: String) throws -> [CartItem] {
        guard let data = json.data(using: .utf8) else {
            throw ParseError.invalidJSON
        }
        let rawItems = try JSONDecoder().decode([RawCartItem].self, from: data)
        return rawItems.compactMap(makeCartItem)
    }

    private static func makeCartItem(from raw: RawCartItem) -> CartItem? {
        guard let title = raw.title, let url = raw.url else { return nil }
        let price = cleanPrice(raw.rawPrice)
        return CartItem(
            id: raw.id ?? url,
            title: title,
            variant: raw.variant,
            price: price,
            quantity: raw.rawQuantity.flatMap { Int($0.trimmingCharacters(in: .whitespaces)) },
            url: url,
            imageURL: raw.imageURL,
            isAvailable: price != nil
        )
    }

    private static func cleanPrice(_ raw: String?) -> Double? {
        guard let raw else { return nil }
        let digitsOnly = raw.filter(\.isNumber)
        guard !digitsOnly.isEmpty else { return nil }
        return Double(digitsOnly)
    }
}