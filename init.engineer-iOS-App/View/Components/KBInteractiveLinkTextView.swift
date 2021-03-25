//
//  KBInteractiveLinkTextView.swift
//  init.engineer-iOS-App
//
//  Created by stephen on 2021/3/25.
//  Copyright © 2021 Kantai Developer. All rights reserved.
//

import UIKit

final class KBInteractiveLinkTextView: UITextView {
    
    private lazy var tap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(actionTap))
        tap.numberOfTapsRequired = 1
        return tap
    }()
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configure()
    }
        
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        configure()
    }

    private func configure() {
        isUserInteractionEnabled = true
        addGestureRecognizer(tap)
        
    }
    
    /// 使用者是否點擊在有效的連結上
    ///
    /// - Parameter point: User tap location point
    private func isTapOnTopOfActivateLink(point: CGPoint) {
        
        // Configure NSLayoutManager and add the text container
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)

        guard let attributedText = attributedText, let font = font else {
            return
        }

        // Configure NSTextStorage and apply the layout manager
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addAttribute(NSAttributedString.Key.font,
                                 value: font,
                                 range: NSRange(location: 0, length: attributedText.length))
        textStorage.addLayoutManager(layoutManager)

        // Get the tapped character location
        let locationOfTouchInLabel = point

        // account for text alignment and insets
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        var alignmentOffset: CGFloat = 0.0
        switch textAlignment {
        case .left, .natural, .justified:
            alignmentOffset = 0.0
        case .center:
            alignmentOffset = 0.5
        case .right:
            alignmentOffset = 1.0
        @unknown default:
            fatalError("alignment out of support boundary")
        }

        let xOffset = ((bounds.size.width - textBoundingBox.size.width) * alignmentOffset) - textBoundingBox.origin.x
        let yOffset = ((bounds.size.height - textBoundingBox.size.height) * alignmentOffset) - textBoundingBox.origin.y
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - xOffset, y: locationOfTouchInLabel.y - yOffset)

        // Which character was tapped
        let characterIndex = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        // Work out how many characters are in the string up to and including the line tapped, to ensure we are not off the end of the character string
        let lineTapped = Int(ceil(locationOfTouchInLabel.y / font.lineHeight)) - 1
        let rightMostPointInLineTapped = CGPoint(x: bounds.size.width, y: font.lineHeight * CGFloat(lineTapped))

        let charsInLineTapped = layoutManager.characterIndex(for: rightMostPointInLineTapped, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < charsInLineTapped else {
            return
        }

        // Open safari while link available
        let attributeName = NSAttributedString.Key.link

        guard let value =
                self.attributedText?.attribute(attributeName, at: characterIndex, effectiveRange: nil) else {
            return
        }

        guard let aURL = value as? URL, UIApplication.shared.canOpenURL(aURL) else {
            return
        }
        UIApplication.shared.open(aURL)
    }
    
    /**
     情境
     
     * 4mr 有 html 語法，所以用 html render 出來，那這樣 label 才能解決 圖片顯示 以及 link 的點擊事情

     * 但又發現 4nu 有 server 傳過來的會是如下

     https://zh.wikipedia.org/wiki/%E5%BE%B7%E5%9B%BD%E5%9D%A6%E5%85%8B%E9%97%AE%E9%A2%98

     所以基於以上兩者推演出三種可能來源

     1. 有 html 語法，一樣用 html render （ 如 4mr ）
     2. 沒有 html 語法，如上面這次 4nu 的狀態（ 如 4nu ）
     3. 沒有 html 語法，但有可能包含其他文字比如

     a text https://link1 b text https://link2
     
     所以解法採用如果發現 link 的話，那就 replace 成 <a href="https://link1">https://link1</a>
     
     */
    private func maybeTransform2HTML(input: String) -> String {
        
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            // If fail to try, return origin sourece
            return input
        }
        
        let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        var inputCopy = input
        
        for match in matches {
            guard let range = Range(match.range, in: input) else { continue }
            let foundURL = input[range]
            let display = (foundURL.removingPercentEncoding ?? String(foundURL))
            inputCopy = inputCopy.replacingOccurrences(of: foundURL, with: String(format: "<a href=\"%@\">%@</a>", foundURL as CVarArg, display))
        }
        return inputCopy
    }

    @objc func actionTap(tap: UITapGestureRecognizer) {
        let point = tap.location(in: self)
        isTapOnTopOfActivateLink(point: point)
    }
}

// ******************************************
//
// MARK: - Public methods
//
// ******************************************
extension KBInteractiveLinkTextView {
    
    func setAttributedTextWithHTMLStyle(source: String) {
                
        let string = source.hasHTMLTag ? source : maybeTransform2HTML(input: source)
    
        attributedText = String(format: """
            <style>
                img {
                    width: 200px;
                    height: 200px;
                }
            </style>
            <span>%@</span>
            """, string).getNSAttributedStringFromHTMLTag()
    }
}