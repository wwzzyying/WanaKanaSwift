import Foundation

/**
 * Creates a romaji to kana mapping tree
 * - Parameters:
 *   - IMEMode: Whether to use IME mode
 *   - useObsoleteKana: Whether to use obsolete kana
 *   - customKanaMapping: Custom mapping overrides
 * - Returns: Mapping dictionary
 */
func createRomajiToKanaMap(
    IMEMode: Bool,
    useObsoleteKana: Bool,
    customKanaMapping: Any? = nil
) -> [String: Any] {
    
    var map = getRomajiToKanaTree()
    
    if IMEMode {
        map = IME_MODE_MAP(map)
    }
    
    if useObsoleteKana {
        map = USE_OBSOLETE_KANA_MAP(map)
    }
    
    if let customMapping = customKanaMapping {
        map = mergeCustomMapping(map, customMapping)
    }
    
    return map
}

/**
 * Convert Romaji to Kana
 * - Parameters:
 *   - input: Text to convert
 *   - options: Configuration options
 *   - map: Optional custom mapping
 * - Returns: Converted text
 *
 * Example:
 * ```
 * toKana("onaji BUTTSUUJI")
 * // => "おなじ ブッツウジ"
 * toKana("ONAJI buttsuuji")
 * // => "オナジ ぶっつうじ"
 * toKana("座禅'zazen'スタイル")
 * // => "座禅「ざぜん」スタイル"
 * toKana("batsuge-mu")
 * // => "ばつげーむ"
 * toKana("!?.:/,~-''""[]()){}")
 * // => "！？。：・、〜ー「」『』［］（）｛｝"
 * toKana("we", options: ["useObsoleteKana": true])
 * // => "ゑ"
 * toKana("wanakana", options: ["customKanaMapping": ["na": "に", "ka": "bana"]])
 * // => "わにbanaに"
 * ```
 */
func _toKana(
    _ input: String = "",
    options: [String: Any] = [:],
    map: [String: String]? = nil
) -> String {
    let config = mergeWithDefaultOptions(options)
    var kanaMap: [String: Any]?
    
    kanaMap = map
    if kanaMap == nil {
        kanaMap = createRomajiToKanaMap(
            IMEMode: config["IMEMode"] as? Bool ?? false,
            useObsoleteKana: config["useObsoleteKana"] as? Bool ?? false,
            customKanaMapping: config["customKanaMapping"]
        )
    }
    
    return splitIntoConvertedKana(input, options: config, map: kanaMap)
        .map { (start, end, kana) in
            if kana == nil {
                // Haven't converted the end of the string, since we are in IME mode
                let startIndex = input.index(input.startIndex, offsetBy: start)
                return String(input[startIndex...])
            }
            
            let enforceHiragana = config["IMEMode"] as? String == TO_KANA_METHODS.HIRAGANA
            let enforceKatakana = config["IMEMode"] as? String == TO_KANA_METHODS.KATAKANA ||
            Array(input[input.index(input.startIndex, offsetBy: start)..<input.index(input.startIndex, offsetBy: end)])
                .allSatisfy { isCharUpperCase(String($0)) }
            
            return enforceHiragana || !enforceKatakana
            ? kana!
            : hiraganaToKatakana(kana!)
        }
        .joined()
}

/**
 * Split input into converted kana tokens
 * - Parameters:
 *   - input: Text to convert
 *   - options: Configuration options
 *   - map: Optional custom mapping
 * - Returns: Array of tokens with start, end, and kana
 */
func splitIntoConvertedKana(
    _ input: String = "",
    options: [String: Any] = [:],
    map: [String: Any]? = nil
) -> [(Int, Int, String?)] {
    let IMEMode = options["IMEMode"] as? Bool ?? false
    let useObsoleteKana = options["useObsoleteKana"] as? Bool ?? false
    let customKanaMapping = options["customKanaMapping"] as? [String: String]
    
    let kanaMap: [String: Any]
    
    if let customMap = map {
        kanaMap = customMap
    } else {
        kanaMap = createRomajiToKanaMap(
            IMEMode: IMEMode,
            useObsoleteKana: useObsoleteKana,
            customKanaMapping: customKanaMapping
        )
    }
    
    return applyMapping(input.lowercased(), map: kanaMap, optimize: !IMEMode)
}
