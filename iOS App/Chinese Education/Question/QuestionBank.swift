import Foundation

// MARK: - 📚 QUESTION BANK MANAGER - Chinese Learning Questions & Passages
class QuestionBank: ObservableObject {
    static let shared = QuestionBank()  // Singleton pattern
    
    // MARK: - 📖 QUESTION STORAGE
    @Published var questions: [Question] = []  // Remote questions from API
    
    // Local questions dictionary for offline use
    private var localQuestions: [String: Question] = [
        "q1": Question(key: "q1", question: "以下哪一項是樂樂在星期六早晨所做的準備？", type: "mc", answer: "B. 佈置花園，掛上氣球和彩帶", choices: ["A. 採摘新鮮胡蘿蔔", "B. 佈置花園，掛上氣球和彩帶", "C. 組織足球比賽", "D. 打掃房間"], explantation: ["樂樂在早晨忙著佈置花園，掛上氣球和彩帶","樂樂在早晨忙著佈置花園，掛上氣球和彩帶","樂樂在早晨忙著佈置花園，掛上氣球和彩帶","樂樂在早晨忙著佈置花園，掛上氣球和彩帶"]),
        "q2": Question(key: "q2", question: "文中敘述了派對進行時的情形，下列哪項描述最完整？", type: "mc", answer: "A. 小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁", choices: ["A. 小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁", "B. 只有小兔子在花園中跳舞","C. 樹上掛滿了彩帶和氣球，但沒有朋友來","D. 小兔子獨自在花園中唱歌"], explantation: ["文中描述小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁","文中描述小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁","文中描述小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁","文中描述小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁"]),
        "q3": Question(key: "q3", question: "從文中可以推測出樂樂舉辦派對的主要原因是：", type: "mc", answer: "A. 想與朋友一起分享快樂", choices: ["A. 想與朋友一起分享快樂", "B. 希望向鄰居炫耀自己的裝飾品", "C. 為了慶祝自己的生日", "D. 打發沒事可做的時間"], explantation: ["從文中可看出，小兔子舉辦派對是為了與朋友一同分享快樂","從文中可看出，小兔子舉辦派對是為了與朋友一同分享快樂","從文中可看出，小兔子舉辦派對是為了與朋友一同分享快樂","從文中可看出，小兔子舉辦派對是為了與朋友一同分享快樂"]),
        "q4": Question(key: "q4", question: "如果你要舉辦一個自己的花園派對，你會如何佈置現場以營造熱鬧氣氛？", type: "mc", answer: "A. 只放置簡單的桌椅，不做裝飾", choices: ["A. 只放置簡單的桌椅，不做裝飾", "B. 掛上彩色氣球、彩帶，並準備美味點心和遊戲區", "C. 把所有東西收起來，只留空曠的場地", "D. 僅播放音樂，不做其他佈置"], explantation: ["選項 B 表示會掛上彩色氣球、彩帶，同時準備美味點心和遊戲區，營造出熱鬧氣氛","選項 B 表示會掛上彩色氣球、彩帶，同時準備美味點心和遊戲區，營造出熱鬧氣氛","選項 B 表示會掛上彩色氣球、彩帶，同時準備美味點心和遊戲區，營造出熱鬧氣氛","選項 B 表示會掛上彩色氣球、彩帶，同時準備美味點心和遊戲區，營造出熱鬧氣氛"]),
        "q5": Question(key: "q5", question: "文章中提到，一年有哪四個季節？", type: "mc", answer: "A. 春、夏、秋、冬", choices: ["A. 春、夏、秋、冬", "B. 春、夏、雨、冬", "C. 春、秋、夏、風", "D. 夏、秋、冬、雪"], explantation: ["文章中提到的一年四季為：春、夏、秋、冬","文章中提到的一年四季為：春、夏、秋、冬","文章中提到的一年四季為：春、夏、秋、冬","文章中提到的一年四季為：春、夏、秋、冬"]),
        "q6": Question(key: "q6", question: "根據文章，春天和秋天各自的主要特徵為何？", type: "mc", answer: "B. 春天萬物甦醒賞花，秋天樹葉變色、豐收在望", choices: ["A. 春天寒冷，秋天炎熱", "B. 春天萬物甦醒賞花，秋天樹葉變色、豐收在望","C. 春天下雪，秋天出現霧氣","D. 春天熱鬧，秋天寧靜"], explantation: ["春天萬物甦醒、賞花，秋天樹葉變色、豐收在望","春天萬物甦醒、賞花，秋天樹葉變色、豐收在望","春天萬物甦醒、賞花，秋天樹葉變色、豐收在望","春天萬物甦醒、賞花，秋天樹葉變色、豐收在望"]),
        "q7": Question(key: "q7", question: "作者認為四季變化能帶來驚喜，最可能的原因是：", type: "mc", answer: "A. 每個季節都有不同的天氣和活動", choices: ["A. 每個季節都有不同的天氣和活動", "B. 每個季節都非常相似", "C. 四季變化只影響植物生長", "D. 四季變化使人感到困惑"], explantation: ["作者指出因為每個季節都有不同的天氣與活動，故季節變化總能帶來驚喜","作者指出因為每個季節都有不同的天氣與活動，故季節變化總能帶來驚喜","作者指出因為每個季節都有不同的天氣與活動，故季節變化總能帶來驚喜","作者指出因為每個季節都有不同的天氣與活動，故季節變化總能帶來驚喜"]),
        "q8": Question(key: "q8", question: "如果你住的地方一年四季分明，你會如何根據各季節安排你的休閒活動？", type: "mc", answer: "B. 根據季節選擇戶外運動、室內閱讀或參加節慶活動，以享受自然的不同風情", choices: ["A. 每個季節都做同樣的活動，不做改變", "B. 根據季節選擇戶外運動、室內閱讀或參加節慶活動，以享受自然的不同風情", "C. 只在夏天外出，其他季節全在家裡休息", "D. 忽略季節變化，隨意安排活動"], explantation: ["依據不同季節來安排戶外運動、室內閱讀或參加節慶活動，享受自然的不同風情","依據不同季節來安排戶外運動、室內閱讀或參加節慶活動，享受自然的不同風情","依據不同季節來安排戶外運動、室內閱讀或參加節慶活動，享受自然的不同風情","依據不同季節來安排戶外運動、室內閱讀或參加節慶活動，享受自然的不同風情"])
    ]

    func fetchQuestions(forSchoolID schoolID: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://toyoueducation.com/api/questions/school123") else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let fetchedQuestions = try? JSONDecoder().decode([Question].self, from: data) else {
                completion(false)
                return
            }

            DispatchQueue.main.async {
                self.questions = fetchedQuestions
                completion(true)
            }
        }.resume()
    }
    
    func getQuestion(forKey key: String) -> Question? {
        return localQuestions[key]
    }
    
    func getPassageSet(for passageKey: String) -> PassageQuestionSet? {
        return passageSets.values.first(where: { $0.passageKey == passageKey })
    }
    
    func getAllQuestions() -> [Question] {
        return Array(localQuestions.values)
    }
    
    func getPassageForQuestion(_ questionKey: String) -> String? {
        for (_, passageSet) in passageSets {
            if passageSet.questionKeys.contains(questionKey) {
                return passageSet.passage
            }
        }
        return nil
    }
    
    func getFullQuestion(forKey questionKey: String) -> String? {
        return localQuestions[questionKey]?.question
    }
}

struct Question: Codable {
    let key: String
    let question: String
    let type: String  // "mc" for multiple choice, "qa" for open-ended
    let answer: String
    let choices: [String]?  // Optional for multiple-choice questions
    let explantation: [String]?
    //let passage: String?  // ✅ New passage field (can be shared across questions)
    
}

struct PassageQuestionSet {
    let passageKey: String
    let passage: String
    let questionKeys: [String]
}

let passageSets = [
    "p1": PassageQuestionSet(
        passageKey: "passage1",
        passage: """
        星期六早晨，當第一縷溫暖的陽光灑落在綠油油的草坪上，小兔子樂樂就興奮地開始忙碌起來。\n從小櫃子裡取出五彩繽紛的氣球和彩帶，精心佈置著自己的花園。\n樂樂一邊掛著裝飾，一邊把自己親手製作的邀請函貼在大樹的小信箱上，希望能邀請到所有好朋友參加派對。不久，派對的鐘聲響起。花園裡，輕盈的小鳥在枝頭嬉戲，活潑的松鼠在樹間跳躍，而溫柔的小鹿也悄悄走近。\n樂樂熱情地迎接每一位來訪的朋友，大家圍在一起分享自製的胡蘿蔔蛋糕與新鮮果汁，歡笑聲和歡呼聲此起彼伏。隨著午後陽光逐漸變得柔和，派對也進入了尾聲。\n朋友們依依不捨地告別，約定下次還要聚在一起玩耍。\n樂樂站在花園中央，看著漸暗的天幕，心中滿懷著回憶與對未來派對的期待。\n回到家後，樂樂細細回味這一天的點滴，心裡暗自決定：下次，他要邀請更多的朋友，一同把這份快樂延續下去。
        """,
        questionKeys: ["q1", "q2", "q3","q4"]
    ),
    
    "p2": PassageQuestionSet(
        passageKey: "passage1",
        passage: """
        一年有四個季節，每一個季節都有它獨特的風景與氣息。\n春天來臨時，萬物開始甦醒，百花齊放，溫柔的春風拂過大地。人們喜歡到公園踏青、賞花和放風箏，感受大自然的生機勃勃。\n夏日陽光燦爛，氣溫漸高。小朋友們在泳池中嬉戲，樹下乘涼的人們則享受著冰涼的飲料。果樹上成熟的果實散發著誘人的香甜味，讓這個季節充滿熱情與活力。\n到了秋天，樹葉漸轉為金黃和火紅，農田裡傳來豐收的忙碌聲。農民們忙於收割稻穀，果園中傳來陣陣果香，秋天彷彿在向人們展示一幅多彩的畫卷。\n冬天則帶來寒冷和靜謐，大地被皚皚白雪覆蓋。人們穿上厚重衣物在雪地上堆雪人、滑雪，享受著冬日獨有的樂趣。\n四季更替，不僅改變了自然景觀，也豐富了人們的生活，讓我們每個月都能感受到不一樣的驚喜與故事。
        """,
        questionKeys: ["q5", "q6", "q7","q8"]
    )
]
