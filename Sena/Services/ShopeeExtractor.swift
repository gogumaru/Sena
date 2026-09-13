//
//  ShopeeExtractor.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//

import Foundation


enum ShopeeExtractor {
    
    static func searchURL(forKeyword keyword: String) -> URL? {
        var components = URLComponents(string: "https://shopee.co.id/search")
        components?.queryItems = [URLQueryItem(name: "keyword", value: keyword)]
        return components?.url
    }
    
    static let homeURL = URL(string: "https://shopee.co.id")!
    


    static let cartURL = URL(string: "https://shopee.co.id/cart")!
    
    static let clickCartIconScript = """
    var cartLink = document.querySelector('.navbar-icon-cart__wrapper');
    if (!cartLink) { return 'not-found'; }
    cartLink.click();
    return 'clicked';
    """


    static let cartItemsScript = """
    function titleFromImageAlt(alt) {
        if (!alt) { return null; }
        var prefix = 'Picture for ';
        return alt.indexOf(prefix) === 0 ? alt.slice(prefix.length).trim() : alt.trim();
    }

    function textOrNull(el) {
        if (!el) { return null; }
        var text = el.textContent;
        return text ? text.trim() : null;
    }

    function attrOrNull(el, attr) {
        if (!el) { return null; }
        return el.getAttribute(attr);
    }

    var cards = document.querySelectorAll('a[href*="-i."]');
    var items = [];

    cards.forEach(function (card) {
        var imgEl = card.querySelector('picture img');
        var priceEl = card.querySelector('.dNCL04');
        var variantEl = card.querySelector('.l6P6Ns');
        var quantityEl = card.querySelector('input[inputmode="numeric"]');

        var href = attrOrNull(card, 'href');
        var title = titleFromImageAlt(attrOrNull(imgEl, 'alt'));

        if (!title || !href) { return; }

        items.push({
            id: href,
            title: title,
            variant: textOrNull(variantEl),
            rawPrice: textOrNull(priceEl),
            rawQuantity: quantityEl ? quantityEl.value : null,
            url: href.indexOf('http') === 0 ? href : ('https://shopee.co.id' + href),
            imageURL: attrOrNull(imgEl, 'src')
        });
    });

    return JSON.stringify(items);
    """
    
    static func triggerSearchScript(keyword: String) -> String {
        let encoded = (try? JSONEncoder().encode(keyword)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
        return """
        var input = document.querySelector('input[name="keyword"]');
        if (!input) { return 'no-input'; }

        var setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
        setter.call(input, \(encoded));
        input.dispatchEvent(new Event('input', { bubbles: true }));
        input.dispatchEvent(new Event('change', { bubbles: true }));

        var form = input.closest('form');
        if (form) {
            form.requestSubmit ? form.requestSubmit() : form.submit();
            return 'submitted';
        }
        return 'no-form';
        """
    }
    
    static let permissionsPolyfillScript = """
        (function () {
            if (!window.navigator.permissions || !window.navigator.permissions.query) { return; }
            var originalQuery = window.navigator.permissions.query.bind(window.navigator.permissions);
            window.navigator.permissions.query = function (descriptor) {
                return originalQuery(descriptor).catch(function () {
                    return Promise.resolve({ state: 'prompt', onchange: null });
                });
            };
        })();
    """
    
    static let searchResultsScript = """
    function textOrNull(el) {
        if (!el) { return null; }
        var text = el.textContent;
        return text ? text.trim() : null;
    }

    function attrOrNull(el, attr) {
        if (!el) { return null; }
        return el.getAttribute(attr);
    }

    function titleFromAriaLabel(label) {
        if (!label) { return null; }
        var prefix = 'View product: ';
        return label.indexOf(prefix) === 0 ? label.slice(prefix.length).trim() : label.trim();
    }

    var cards = document.querySelectorAll('[role="group"][aria-label^="Product card:"]');
    var products = [];

    cards.forEach(function (card) {
        var linkEl = card.querySelector('a');
        var priceEl = card.querySelector('.truncate.flex.items-baseline');
        var ratingEl = card.querySelector('img[alt="rating-star"]  span');
        var soldCountEl = card.querySelector('.text-shopee-black87.text-sp10');
        var imageEl = card.querySelector('img[elementtiming="shopee:heroComponentPaint"]');

        var href = attrOrNull(linkEl, 'href');
        var title = titleFromAriaLabel(attrOrNull(linkEl, 'aria-label'));

        if (!title || !href) { return; }

        products.push({
            id: href,
            title: title,
            rawPrice: textOrNull(priceEl),
            rawRating: textOrNull(ratingEl),
            rawSoldCount: textOrNull(soldCountEl),
            seller: null,
            url: href.indexOf('http') === 0 ? href : ('https://shopee.co.id' + href),
            imageURL: attrOrNull(imageEl, 'src')
        });
    });

    return JSON.stringify(products);
    """
}
