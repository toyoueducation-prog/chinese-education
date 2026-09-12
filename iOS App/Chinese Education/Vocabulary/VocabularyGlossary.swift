import Foundation

/**
 * Offline curated glosses for passage vocabulary.
 * Practice only uses words that resolve to a non-empty meaning here
 * (or already stored with a meaning). Extracted chars/bigrams without
 * a gloss are kept for list tracking but never treated as "known."
 */
enum VocabularyGlossary {
    struct Entry {
        let pinyin: String
        let meaning: String
    }

    /// Key vocabulary drawn from the nine local passages (Traditional Chinese glosses).
    static let entries: [String: Entry] = [
        // Passage 1 — 小兔子的派對
        "派對": Entry(pinyin: "pài duì", meaning: "聚會慶祝的活動"),
        "花園": Entry(pinyin: "huā yuán", meaning: "種植花草的園子"),
        "氣球": Entry(pinyin: "qì qiú", meaning: "充氣後會飄浮的彩色球"),
        "彩帶": Entry(pinyin: "cǎi dài", meaning: "用來裝飾的彩色帶子"),
        "邀請": Entry(pinyin: "yāo qǐng", meaning: "請別人來參加"),
        "朋友": Entry(pinyin: "péng yǒu", meaning: "彼此友善、互相關心的人"),
        "分享": Entry(pinyin: "fēn xiǎng", meaning: "把東西或快樂分給別人"),
        "蛋糕": Entry(pinyin: "dàn gāo", meaning: "用麵粉和蛋做成的甜點"),
        "果汁": Entry(pinyin: "guǒ zhī", meaning: "用水果榨成的飲料"),
        "快樂": Entry(pinyin: "kuài lè", meaning: "開心、愉快的感覺"),
        "忙碌": Entry(pinyin: "máng lù", meaning: "事情很多、很忙"),
        "佈置": Entry(pinyin: "bù zhì", meaning: "把地方裝飾整理好"),
        "歡迎": Entry(pinyin: "huān yíng", meaning: "高興地迎接別人"),
        "期待": Entry(pinyin: "qī dài", meaning: "盼望將來發生的事"),
        "陽光": Entry(pinyin: "yáng guāng", meaning: "太陽照下來的光線"),
        "草坪": Entry(pinyin: "cǎo píng", meaning: "長滿草的平地"),
        "兔子": Entry(pinyin: "tù zi", meaning: "長耳朵的小動物"),
        "松鼠": Entry(pinyin: "sōng shǔ", meaning: "會爬樹、愛吃堅果的小動物"),
        "小鳥": Entry(pinyin: "xiǎo niǎo", meaning: "小小的鳥"),
        "小鹿": Entry(pinyin: "xiǎo lù", meaning: "小小的鹿"),

        // Passage 2 — 四季變化
        "季節": Entry(pinyin: "jì jié", meaning: "一年中的春夏秋冬"),
        "春天": Entry(pinyin: "chūn tiān", meaning: "一年中天氣轉暖、花開的季節"),
        "夏天": Entry(pinyin: "xià tiān", meaning: "一年中最炎熱的季節"),
        "秋天": Entry(pinyin: "qiū tiān", meaning: "樹葉變色、農作物豐收的季節"),
        "冬天": Entry(pinyin: "dōng tiān", meaning: "一年中最寒冷的季節"),
        "甦醒": Entry(pinyin: "sū xǐng", meaning: "從睡眠或靜止中醒來"),
        "風景": Entry(pinyin: "fēng jǐng", meaning: "眼前所見的自然景色"),
        "踏青": Entry(pinyin: "tà qīng", meaning: "春天到郊外散步賞景"),
        "豐收": Entry(pinyin: "fēng shōu", meaning: "農作物收成很多"),
        "寒冷": Entry(pinyin: "hán lěng", meaning: "天氣很冷"),
        "靜謐": Entry(pinyin: "jìng mì", meaning: "安靜而平和"),
        "驚喜": Entry(pinyin: "jīng xǐ", meaning: "意想不到的開心事"),
        "大自然": Entry(pinyin: "dà zì rán", meaning: "天然的環境與景物"),
        "活力": Entry(pinyin: "huó lì", meaning: "充滿能量、生氣勃勃"),

        // Passage 3 — 小鳥的遷徙
        "遷徙": Entry(pinyin: "qiān xǐ", meaning: "為了生存而長途遷移"),
        "氣候": Entry(pinyin: "qì hòu", meaning: "一個地方長期的天氣狀況"),
        "食物": Entry(pinyin: "shí wù", meaning: "可以吃的東西"),
        "飛行": Entry(pinyin: "fēi xíng", meaning: "在空中飛"),
        "導航": Entry(pinyin: "dǎo háng", meaning: "辨認方向、找到路"),
        "挑戰": Entry(pinyin: "tiǎo zhàn", meaning: "需要努力克服的困難"),
        "適應": Entry(pinyin: "shì yìng", meaning: "配合環境而改變自己"),
        "生存": Entry(pinyin: "shēng cún", meaning: "繼續活下去"),
        "繁殖": Entry(pinyin: "fán zhí", meaning: "生育下一代"),
        "科學家": Entry(pinyin: "kē xué jiā", meaning: "從事科學研究的人"),
        "保護": Entry(pinyin: "bǎo hù", meaning: "使不受傷害"),
        "濕地": Entry(pinyin: "shī dì", meaning: "長期潮濕的土地，鳥類常棲息"),
        "森林": Entry(pinyin: "sēn lín", meaning: "樹木茂密的大片土地"),
        "環境": Entry(pinyin: "huán jìng", meaning: "周圍的自然或生活條件"),

        // Passage 4 — 小貓咪的冒險
        "冒險": Entry(pinyin: "mào xiǎn", meaning: "去做有風險但可能有趣的事"),
        "好奇": Entry(pinyin: "hào qí", meaning: "想知道更多的心情"),
        "溫暖": Entry(pinyin: "wēn nuǎn", meaning: "不冷、令人感到舒服"),
        "舒適": Entry(pinyin: "shū shì", meaning: "感覺自在、好過"),
        "危險": Entry(pinyin: "wēi xiǎn", meaning: "可能造成傷害"),
        "探索": Entry(pinyin: "tàn suǒ", meaning: "去發現未知的事物"),
        "自由": Entry(pinyin: "zì yóu", meaning: "不受限制、可以自己決定"),
        "感激": Entry(pinyin: "gǎn jī", meaning: "感謝別人的幫助或關愛"),
        "安全": Entry(pinyin: "ān quán", meaning: "沒有危險"),
        "主人": Entry(pinyin: "zhǔ rén", meaning: "照顧寵物或家的人"),
        "小貓": Entry(pinyin: "xiǎo māo", meaning: "小小的貓"),
        "小狗": Entry(pinyin: "xiǎo gǒu", meaning: "小小的狗"),

        // Passage 5 — 植物的生長
        "植物": Entry(pinyin: "zhí wù", meaning: "會進行光合作用的生物，如花草樹木"),
        "生長": Entry(pinyin: "shēng zhǎng", meaning: "逐漸長大"),
        "陽光": Entry(pinyin: "yáng guāng", meaning: "太陽照下來的光線"),
        "水分": Entry(pinyin: "shuǐ fèn", meaning: "水的含量"),
        "土壤": Entry(pinyin: "tǔ rǎng", meaning: "地上能種花種菜的泥土"),
        "空氣": Entry(pinyin: "kōng qì", meaning: "包圍地球、可供呼吸的氣體"),
        "光合作用": Entry(pinyin: "guāng hé zuò yòng", meaning: "植物用陽光製造養分的過程"),
        "種子": Entry(pinyin: "zhǒng zi", meaning: "能長成新植物的小小顆粒"),
        "發芽": Entry(pinyin: "fā yá", meaning: "種子長出新芽"),
        "養分": Entry(pinyin: "yǎng fèn", meaning: "幫助生長的營養物質"),
        "生態系統": Entry(pinyin: "shēng tài xì tǒng", meaning: "生物與環境互相影響的整體"),
        "照顧": Entry(pinyin: "zhào gù", meaning: "用心看護、照料"),

        // Passage 6 — 小明的圖書館之旅
        "圖書館": Entry(pinyin: "tú shū guǎn", meaning: "收藏書籍、供人閱讀的地方"),
        "閱讀": Entry(pinyin: "yuè dú", meaning: "看書、讀文章"),
        "書籍": Entry(pinyin: "shū jí", meaning: "書本的總稱"),
        "書架": Entry(pinyin: "shū jià", meaning: "放書的架子"),
        "冒險": Entry(pinyin: "mào xiǎn", meaning: "去做有風險但可能有趣的事"),
        "知識": Entry(pinyin: "zhī shì", meaning: "透過學習得到的理解"),
        "好奇": Entry(pinyin: "hào qí", meaning: "想知道更多的心情"),
        "故事": Entry(pinyin: "gù shi", meaning: "有情節的敘述"),
        "世界": Entry(pinyin: "shì jiè", meaning: "我們生活的廣大範圍"),
        "興趣": Entry(pinyin: "xìng qù", meaning: "對某事特別喜歡、想了解"),
        "推薦": Entry(pinyin: "tuī jiàn", meaning: "介紹給別人認為適合的東西"),

        // Passage 7 — 太陽系的行星
        "太陽系": Entry(pinyin: "tài yáng xì", meaning: "太陽和圍繞它運行的天體"),
        "行星": Entry(pinyin: "xíng xīng", meaning: "圍繞恆星運行的天體"),
        "水星": Entry(pinyin: "shuǐ xīng", meaning: "距離太陽最近的行星"),
        "金星": Entry(pinyin: "jīn xīng", meaning: "太陽系中第二顆行星"),
        "地球": Entry(pinyin: "dì qiú", meaning: "我們居住的行星"),
        "火星": Entry(pinyin: "huǒ xīng", meaning: "表面呈紅色的行星"),
        "木星": Entry(pinyin: "mù xīng", meaning: "太陽系中最大的行星"),
        "土星": Entry(pinyin: "tǔ xīng", meaning: "有美麗光環的行星"),
        "宇宙": Entry(pinyin: "yǔ zhòu", meaning: "包含所有星體與空間的整體"),
        "溫度": Entry(pinyin: "wēn dù", meaning: "冷熱的程度"),
        "大氣層": Entry(pinyin: "dà qì céng", meaning: "包圍行星的氣體層"),
        "生命": Entry(pinyin: "shēng mìng", meaning: "能生長、繁殖的生物狀態"),
        "探索": Entry(pinyin: "tàn suǒ", meaning: "去發現未知的事物"),
        "特徵": Entry(pinyin: "tè zhēng", meaning: "與眾不同的特點"),

        // Passage 8 — 傳統節日
        "傳統": Entry(pinyin: "chuán tǒng", meaning: "世代流傳下來的習俗或文化"),
        "節日": Entry(pinyin: "jié rì", meaning: "特別慶祝的日子"),
        "春節": Entry(pinyin: "chūn jié", meaning: "農曆新年，家人團聚的節日"),
        "中秋節": Entry(pinyin: "zhōng qiū jié", meaning: "賞月吃月餅的團圓節日"),
        "端午節": Entry(pinyin: "duān wǔ jié", meaning: "划龍舟、吃粽子的節日"),
        "團聚": Entry(pinyin: "tuán jù", meaning: "家人或朋友聚在一起"),
        "年夜飯": Entry(pinyin: "nián yè fàn", meaning: "除夕晚上全家一起吃的豐盛晚餐"),
        "文化": Entry(pinyin: "wén huà", meaning: "一個群體共同的生活方式與價值"),
        "傳承": Entry(pinyin: "chuán chéng", meaning: "把文化或技藝交給下一代"),
        "慶祝": Entry(pinyin: "qìng zhù", meaning: "為特別的事開心紀念"),
        "祝福": Entry(pinyin: "zhù fú", meaning: "希望別人得到好運"),
        "團圓": Entry(pinyin: "tuán yuán", meaning: "分開的人再次聚在一起"),

        // Passage 9 — 學校的回收日
        "回收": Entry(pinyin: "huí shōu", meaning: "把可再利用的物品收集起來"),
        "分類": Entry(pinyin: "fēn lèi", meaning: "依照種類分開整理"),
        "塑膠": Entry(pinyin: "sù jiāo", meaning: "常見的人工製成材料"),
        "金屬": Entry(pinyin: "jīn shǔ", meaning: "如鐵、鋁等硬質材料"),
        "資源": Entry(pinyin: "zī yuán", meaning: "可供利用的材料或能量"),
        "環保": Entry(pinyin: "huán bǎo", meaning: "保護環境、減少污染"),
        "垃圾": Entry(pinyin: "lā jī", meaning: "丟掉的廢棄物"),
        "合作": Entry(pinyin: "hé zuò", meaning: "一起努力完成事情"),
        "地球": Entry(pinyin: "dì qiú", meaning: "我們居住的行星"),
        "耐心": Entry(pinyin: "nài xīn", meaning: "不急躁、能持續努力"),
        "規則": Entry(pinyin: "guī zé", meaning: "大家共同遵守的約定"),
        "產品": Entry(pinyin: "chǎn pǐn", meaning: "製造出來的物品")
    ]

    static func lookup(_ word: String) -> Entry? {
        entries[word]
    }

    static func hasUsableMeaning(_ word: VocabularyWord) -> Bool {
        let trimmed = word.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }

    static func gloss(for word: String, existingPinyin: String = "", existingMeaning: String = "") -> (pinyin: String, meaning: String) {
        if let entry = lookup(word) {
            let pinyin = existingPinyin.isEmpty ? entry.pinyin : existingPinyin
            let meaning = existingMeaning.isEmpty ? entry.meaning : existingMeaning
            return (pinyin, meaning)
        }
        return (existingPinyin, existingMeaning)
    }
}
