//
//  ProductParser.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//


import Foundation

/// Converts the raw JSON produced by `ShopeeExtractor`'s JavaScript into
/// an array of typed `Product` values.
///
/// The JavaScript side deliberately returns *strings* for numeric-looking
/// fields (price, rating, review count) because Shopee formats them in
/// several different ways ("Rp150.000", "4,8", "1,2rb", ...). Cleaning
/// and converting those strings happens here, in one place, instead of
/// inside the JavaScript.
enum ProductParser {

    /// Mirrors the shape of one product object returned by the extractor
    /// JavaScript. Every field is optional/String because the raw DOM
    /// text is never guaranteed to be present or well formed.
    private struct RawProduct: Decodable {
        let id: String?
        let title: String?
        let rawPrice: String?
        let rawRating: String?
        let rawSoldCount: String?
        let seller: String?
        let url: String?
        let imageURL: String?
    }

    enum ParseError: Error {
        case invalidJSON
    }

    /// Parses a JSON string containing an array of raw product objects.
    /// Entries missing a `title` or `url` are dropped, since those two
    /// fields are the minimum needed for a usable `Product`.
    static func parse(json: String) throws -> [Product] {
        guard let data = json.data(using: .utf8) else {
            throw ParseError.invalidJSON
        }
        let rawProducts = try JSONDecoder().decode([RawProduct].self, from: data)
        return rawProducts.compactMap(makeProduct)
    }

    private static func makeProduct(from raw: RawProduct) -> Product? {
        guard let title = raw.title, let url = raw.url else {
            return nil
        }
        let id = raw.id ?? url
        return Product(
            id: id,
            title: title,
            price: cleanPrice(raw.rawPrice),
            rating: cleanRating(raw.rawRating),
            soldCount: cleanSoldCount(raw.rawSoldCount),
            seller: raw.seller,
            url: url,
            imageURL: raw.imageURL
        )
    }

    /// Turns strings like "Rp150.000" or "150.000" into 150000.0.
    /// Returns nil if no digits could be found.
    private static func cleanPrice(_ raw: String?) -> Double? {
        guard let raw else { return nil }
        let digitsOnly = raw.filter(\.isNumber)
        guard !digitsOnly.isEmpty else { return nil }
        return Double(digitsOnly)
    }

    /// Turns strings like "4,8" or "4.8" into 4.8.
    private static func cleanRating(_ raw: String?) -> Double? {
        guard let raw else { return nil }
        let normalized = raw.replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        return Double(normalized)
    }

    /// Turns strings like "1,2rb" (ribu / thousand) or "234" into an Int.
    /// Shopee abbreviates review counts above 1000 with "rb" (from
    /// "ribu").
    private static func cleanSoldCount(_ raw: String?) -> Int? {
       guard let raw else { return nil }
        let lowercased = raw.lowercased()
        let isThousands = lowercased.contains("rb")
        let digitsAndSeparators = lowercased.filter { $0.isNumber || $0 == "," || $0 == "." }
        let normalized = digitsAndSeparators.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized) else { return nil }
        return Int(isThousands ? value * 1000 : value)
    }
}
