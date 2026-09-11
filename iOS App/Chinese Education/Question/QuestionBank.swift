import Foundation

/**
 * QUESTION BANK - Chinese Learning Questions & Passages Database
 * 
 * This class manages all educational content including:
 * - Questions (multiple choice and open-ended)
 * - Reading passages
 * - PIRLS framework classification
 * - Local storage with Alibaba ECS backend sync
 * 
 * Data Structure:
 * - Questions stored in `localQuestions` dictionary (q1, q2, q3, etc.)
 * - Passages stored in `passageSets` dictionary (passage1, passage2, etc.)
 * - Each passage set contains 4 related questions
 * - Questions enriched with PIRLS process classification
 * 
 * Features:
 * - Local-first storage (all questions/passages stored in app)
 * - Optional Alibaba ECS backend sync for AI-powered features
 * - PIRLS framework integration (Retrieving, Inferring, Interpreting, Evaluating)
 * - Difficulty level estimation (1-6 for primary school levels)
 * - Vocabulary extraction from passages
 * 
 * Usage:
 * - Call `getQuestion(forKey:)` to retrieve a question
 * - Call `getPassageSet(for:)` to get a passage with its questions
 * - Questions automatically enriched with PIRLS data when retrieved
 */

// MARK: - 🌐 API CONFIGURATION - Question Bank Endpoints
/**
 * Defines API endpoints for Alibaba ECS backend integration.
 * All endpoints are optional - app works fully offline with local data.
 */
struct QuestionBankAPI {
    // Alibaba ECS primary endpoint (configure your Alibaba ECS server URL here)
    static let alibabaECSBaseURL = "https://your-alibaba-ecs-server.com/api"  // ✅ Replace with your Alibaba ECS URL
    
    // Question endpoints
    static func questionURL(forKey key: String) -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/passage-question/\(key)")
    }
    
    // Passage endpoints
    static func passageURL(forKey key: String) -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/passage-question/\(key)")
    }
    
    // School questions endpoint
    static func schoolQuestionsURL(forSchoolID schoolID: String) -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/questions/\(schoolID)")
    }
    
    // MARK: - AI-Powered API Endpoints
    static func analyzeReadingComprehensionURL() -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/analyze-reading-comprehension")
    }
    
    static func generatePersonalizedQuestionsURL() -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/generate-personalized-questions")
    }
    
    static func updateDifficultyURL() -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/update-difficulty")
    }
    
    static func vocabularyTrackingURL() -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/track-vocabulary")
    }
    
    static func studentProgressURL() -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/student-progress")
    }
    
    static func pirlsAssessmentURL() -> URL? {
        return URL(string: "\(alibabaECSBaseURL)/pirls-assessment")
    }
}

// MARK: - 📚 QUESTION BANK MANAGER - Chinese Learning Questions & Passages
class QuestionBank: ObservableObject {
    static let shared = QuestionBank()  // Singleton pattern
    
    // MARK: - 📖 QUESTION STORAGE
    @Published var questions: [Question] = []  // Remote questions from API
    
    // Local questions dictionary for offline use - EXPANDED QUESTION BANK
    private var localQuestions: [String: Question] = [
        // ========== PASSAGE 1: 小兔子的派對 (Literary, P1-P2) ==========
        "q1": Question(key: "q1", question: "以下哪一項是樂樂在星期六早晨所做的準備？", type: "mc", answer: "B. 佈置花園，掛上氣球和彩帶", choices: ["A. 採摘新鮮胡蘿蔔", "B. 佈置花園，掛上氣球和彩帶", "C. 組織足球比賽", "D. 打掃房間"], explantation: ["樂樂在早晨忙著佈置花園，掛上氣球和彩帶"], pirlsProcess: .retrieving, difficultyLevel: 1, readingPurpose: .literary),
        "q2": Question(key: "q2", question: "文中敘述了派對進行時的情形，下列哪項描述最完整？", type: "mc", answer: "A. 小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁", choices: ["A. 小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁", "B. 只有小兔子在花園中跳舞","C. 樹上掛滿了彩帶和氣球，但沒有朋友來","D. 小兔子獨自在花園中唱歌"], explantation: ["文中描述小鳥、松鼠和小鹿都在花園裡玩耍，大家一起分享蛋糕和果汁"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .literary),
        "q3": Question(key: "q3", question: "從文中可以推測出樂樂舉辦派對的主要原因是：", type: "mc", answer: "A. 想與朋友一起分享快樂", choices: ["A. 想與朋友一起分享快樂", "B. 希望向鄰居炫耀自己的裝飾品", "C. 為了慶祝自己的生日", "D. 打發沒事可做的時間"], explantation: ["從文中可看出，小兔子舉辦派對是為了與朋友一同分享快樂"], pirlsProcess: .inferring, difficultyLevel: 2, readingPurpose: .literary),
        "q4": Question(key: "q4", question: "如果你要舉辦一個自己的花園派對，你會如何佈置現場以營造熱鬧氣氛？", type: "mc", answer: "B. 掛上彩色氣球、彩帶，並準備美味點心和遊戲區", choices: ["A. 只放置簡單的桌椅，不做裝飾", "B. 掛上彩色氣球、彩帶，並準備美味點心和遊戲區", "C. 把所有東西收起來，只留空曠的場地", "D. 僅播放音樂，不做其他佈置"], explantation: ["選項 B 表示會掛上彩色氣球、彩帶，同時準備美味點心和遊戲區，營造出熱鬧氣氛"], pirlsProcess: .evaluating, difficultyLevel: 2, readingPurpose: .literary),
        
        // ========== PASSAGE 2: 四季變化 (Informational, P2-P3) ==========
        "q5": Question(key: "q5", question: "文章中提到，一年有哪四個季節？", type: "mc", answer: "A. 春、夏、秋、冬", choices: ["A. 春、夏、秋、冬", "B. 春、夏、雨、冬", "C. 春、秋、夏、風", "D. 夏、秋、冬、雪"], explantation: ["文章中提到的一年四季為：春、夏、秋、冬"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .informational),
        "q6": Question(key: "q6", question: "根據文章，春天和秋天各自的主要特徵為何？", type: "mc", answer: "B. 春天萬物甦醒賞花，秋天樹葉變色、豐收在望", choices: ["A. 春天寒冷，秋天炎熱", "B. 春天萬物甦醒賞花，秋天樹葉變色、豐收在望","C. 春天下雪，秋天出現霧氣","D. 春天熱鬧，秋天寧靜"], explantation: ["春天萬物甦醒、賞花，秋天樹葉變色、豐收在望"], pirlsProcess: .interpreting, difficultyLevel: 3, readingPurpose: .informational),
        "q7": Question(key: "q7", question: "作者認為四季變化能帶來驚喜，最可能的原因是：", type: "mc", answer: "A. 每個季節都有不同的天氣和活動", choices: ["A. 每個季節都有不同的天氣和活動", "B. 每個季節都非常相似", "C. 四季變化只影響植物生長", "D. 四季變化使人感到困惑"], explantation: ["作者指出因為每個季節都有不同的天氣與活動，故季節變化總能帶來驚喜"], pirlsProcess: .inferring, difficultyLevel: 3, readingPurpose: .informational),
        "q8": Question(key: "q8", question: "如果你住的地方一年四季分明，你會如何根據各季節安排你的休閒活動？", type: "mc", answer: "B. 根據季節選擇戶外運動、室內閱讀或參加節慶活動，以享受自然的不同風情", choices: ["A. 每個季節都做同樣的活動，不做改變", "B. 根據季節選擇戶外運動、室內閱讀或參加節慶活動，以享受自然的不同風情", "C. 只在夏天外出，其他季節全在家裡休息", "D. 忽略季節變化，隨意安排活動"], explantation: ["依據不同季節來安排戶外運動、室內閱讀或參加節慶活動，享受自然的不同風情"], pirlsProcess: .evaluating, difficultyLevel: 3, readingPurpose: .informational),
        
        // ========== PASSAGE 3: 小鳥的遷徙 (Informational, P3-P4) ==========
        "q9": Question(key: "q9", question: "文章中提到，小鳥為什麼要遷徙？", type: "mc", answer: "A. 為了尋找更適合的氣候和食物", choices: ["A. 為了尋找更適合的氣候和食物", "B. 因為他們喜歡旅行", "C. 為了逃避天敵", "D. 因為他們迷路了"], explantation: ["文章明確說明小鳥遷徙是為了尋找更適合的氣候和食物"], pirlsProcess: .retrieving, difficultyLevel: 3, readingPurpose: .informational),
        "q10": Question(key: "q10", question: "從文中可以推測，小鳥在遷徙過程中面臨的最大挑戰是什麼？", type: "mc", answer: "C. 長途飛行需要大量體力和面對天氣變化", choices: ["A. 找不到同伴", "B. 不知道方向", "C. 長途飛行需要大量體力和面對天氣變化", "D. 沒有地方休息"], explantation: ["文中提到小鳥需要飛行數千公里，並要面對各種天氣變化，這是最主要的挑戰"], pirlsProcess: .inferring, difficultyLevel: 4, readingPurpose: .informational),
        "q11": Question(key: "q11", question: "文章描述小鳥遷徙的過程，主要想說明什麼？", type: "mc", answer: "B. 遷徙是鳥類適應環境的重要生存策略", choices: ["A. 小鳥很聰明", "B. 遷徙是鳥類適應環境的重要生存策略", "C. 遷徙很危險", "D. 小鳥喜歡冒險"], explantation: ["文章通過描述遷徙過程，說明這是鳥類適應環境變化的重要生存策略"], pirlsProcess: .interpreting, difficultyLevel: 4, readingPurpose: .informational),
        "q12": Question(key: "q12", question: "你認為人類應該如何保護遷徙中的鳥類？", type: "mc", answer: "D. 保護濕地和森林，減少環境污染，建立保護區", choices: ["A. 捕捉所有遷徙的鳥類", "B. 阻止鳥類遷徙", "C. 不需要特別保護", "D. 保護濕地和森林，減少環境污染，建立保護區"], explantation: ["保護鳥類的棲息地、減少污染和建立保護區是保護遷徙鳥類的有效方法"], pirlsProcess: .evaluating, difficultyLevel: 4, readingPurpose: .informational),
        
        // ========== PASSAGE 4: 小貓咪的冒險 (Literary, P2-P3) ==========
        "q13": Question(key: "q13", question: "小貓咪第一次離開家時，遇到了什麼？", type: "mc", answer: "A. 一隻友善的小狗", choices: ["A. 一隻友善的小狗", "B. 一隻兇猛的老虎", "C. 一隻會飛的鳥", "D. 一條河流"], explantation: ["文中提到小貓咪第一次離開家時遇到了一隻友善的小狗"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .literary),
        "q14": Question(key: "q14", question: "從故事中可以推測，小貓咪為什麼決定回家？", type: "mc", answer: "B. 它想念家人，也意識到家的溫暖", choices: ["A. 因為外面太危險", "B. 它想念家人，也意識到家的溫暖", "C. 因為迷路了", "D. 因為肚子餓了"], explantation: ["從故事中可以看出，小貓咪在冒險後想念家人，意識到家的溫暖"], pirlsProcess: .inferring, difficultyLevel: 3, readingPurpose: .literary),
        "q15": Question(key: "q15", question: "這個故事想要告訴讀者什麼道理？", type: "mc", answer: "C. 家是最溫暖的地方，冒險後總會想回家", choices: ["A. 不要離開家", "B. 外面很危險", "C. 家是最溫暖的地方，冒險後總會想回家", "D. 小貓咪很勇敢"], explantation: ["故事通過小貓咪的冒險經歷，傳達了家是最溫暖的地方這個道理"], pirlsProcess: .interpreting, difficultyLevel: 3, readingPurpose: .literary),
        "q16": Question(key: "q16", question: "如果你是小貓咪，你會選擇冒險還是留在家裡？為什麼？", type: "mc", answer: "D. 適度冒險可以增長見識，但家永遠是最重要的", choices: ["A. 永遠留在家裡，因為最安全", "B. 永遠冒險，因為很有趣", "C. 不知道該怎麼辦", "D. 適度冒險可以增長見識，但家永遠是最重要的"], explantation: ["適度冒險可以增長見識，但家永遠是最重要的，這是最平衡的選擇"], pirlsProcess: .evaluating, difficultyLevel: 3, readingPurpose: .literary),
        
        // ========== PASSAGE 5: 植物的生長 (Informational, P3-P4) ==========
        "q17": Question(key: "q17", question: "文章中提到，植物生長需要哪些基本條件？", type: "mc", answer: "A. 陽光、水分、土壤和空氣", choices: ["A. 陽光、水分、土壤和空氣", "B. 只有陽光", "C. 只有水分", "D. 不需要任何條件"], explantation: ["文章明確說明植物生長需要陽光、水分、土壤和空氣"], pirlsProcess: .retrieving, difficultyLevel: 3, readingPurpose: .informational),
        "q18": Question(key: "q18", question: "從文中可以推測，為什麼有些植物長得比其他植物快？", type: "mc", answer: "B. 因為它們獲得了更充足的陽光、水分和養分", choices: ["A. 因為它們比較聰明", "B. 因為它們獲得了更充足的陽光、水分和養分", "C. 因為它們比較大", "D. 沒有原因"], explantation: ["根據文章內容，植物生長速度取決於獲得的陽光、水分和養分是否充足"], pirlsProcess: .inferring, difficultyLevel: 4, readingPurpose: .informational),
        "q19": Question(key: "q19", question: "文章描述植物生長的過程，主要想說明什麼？", type: "mc", answer: "C. 植物生長是一個需要多種條件配合的複雜過程", choices: ["A. 植物很容易生長", "B. 植物不需要照顧", "C. 植物生長是一個需要多種條件配合的複雜過程", "D. 所有植物都一樣"], explantation: ["文章通過描述植物生長需要的各種條件，說明這是一個複雜的過程"], pirlsProcess: .interpreting, difficultyLevel: 4, readingPurpose: .informational),
        "q20": Question(key: "q20", question: "你認為照顧植物最重要的是什麼？", type: "mc", answer: "D. 提供適當的陽光、水分和養分，並持續觀察", choices: ["A. 每天澆很多水", "B. 放在陰暗的地方", "C. 不需要照顧", "D. 提供適當的陽光、水分和養分，並持續觀察"], explantation: ["適當的照顧包括提供適量的陽光、水分和養分，並持續觀察植物狀態"], pirlsProcess: .evaluating, difficultyLevel: 4, readingPurpose: .informational),
        
        // ========== PASSAGE 6: 小明的圖書館之旅 (Literary, P4-P5) ==========
        "q21": Question(key: "q21", question: "小明第一次去圖書館時，最吸引他的是什麼？", type: "mc", answer: "B. 書架上排列整齊的各種書籍", choices: ["A. 圖書館的建築", "B. 書架上排列整齊的各種書籍", "C. 圖書館的椅子", "D. 圖書館的燈光"], explantation: ["文中提到小明被書架上排列整齊的各種書籍所吸引"], pirlsProcess: .retrieving, difficultyLevel: 4, readingPurpose: .literary),
        "q22": Question(key: "q22", question: "從故事中可以推測，小明為什麼會愛上閱讀？", type: "mc", answer: "C. 因為他發現書本可以帶他進入不同的世界", choices: ["A. 因為老師要求", "B. 因為父母要求", "C. 因為他發現書本可以帶他進入不同的世界", "D. 因為沒有其他事情做"], explantation: ["從故事中可以看出，小明通過閱讀發現書本可以帶他進入不同的世界，因此愛上閱讀"], pirlsProcess: .inferring, difficultyLevel: 5, readingPurpose: .literary),
        "q23": Question(key: "q23", question: "這個故事想要傳達給讀者什麼訊息？", type: "mc", answer: "A. 閱讀可以開啟知識的大門，豐富我們的心靈", choices: ["A. 閱讀可以開啟知識的大門，豐富我們的心靈", "B. 圖書館很漂亮", "C. 小明很聰明", "D. 書本很重"], explantation: ["故事通過小明的經歷，傳達了閱讀可以開啟知識大門、豐富心靈的訊息"], pirlsProcess: .interpreting, difficultyLevel: 5, readingPurpose: .literary),
        "q24": Question(key: "q24", question: "你認為閱讀對學生的成長有什麼重要性？", type: "mc", answer: "D. 閱讀可以擴展知識、培養思考能力和提升語言表達", choices: ["A. 閱讀沒有用處", "B. 閱讀只是打發時間", "C. 閱讀很無聊", "D. 閱讀可以擴展知識、培養思考能力和提升語言表達"], explantation: ["閱讀對學生成長的重要性包括擴展知識、培養思考能力和提升語言表達"], pirlsProcess: .evaluating, difficultyLevel: 5, readingPurpose: .literary),
        
        // ========== PASSAGE 7: 太陽系的行星 (Informational, P5-P6) ==========
        "q25": Question(key: "q25", question: "文章中提到，太陽系中有幾顆行星？", type: "mc", answer: "A. 八顆", choices: ["A. 八顆", "B. 九顆", "C. 七顆", "D. 十顆"], explantation: ["文章明確說明太陽系中有八顆行星"], pirlsProcess: .retrieving, difficultyLevel: 5, readingPurpose: .informational),
        "q26": Question(key: "q26", question: "從文中可以推測，為什麼水星和金星表面溫度很高？", type: "mc", answer: "B. 因為它們距離太陽很近，接收大量太陽熱量", choices: ["A. 因為它們很大", "B. 因為它們距離太陽很近，接收大量太陽熱量", "C. 因為它們有火山", "D. 沒有原因"], explantation: ["根據文章內容，水星和金星距離太陽很近，因此接收大量太陽熱量，表面溫度很高"], pirlsProcess: .inferring, difficultyLevel: 6, readingPurpose: .informational),
        "q27": Question(key: "q27", question: "文章描述太陽系各行星的特徵，主要想說明什麼？", type: "mc", answer: "C. 每個行星都有其獨特的特徵和環境條件", choices: ["A. 所有行星都一樣", "B. 只有地球適合生命", "C. 每個行星都有其獨特的特徵和環境條件", "D. 行星沒有差異"], explantation: ["文章通過描述各行星的不同特徵，說明每個行星都有其獨特的環境條件"], pirlsProcess: .interpreting, difficultyLevel: 6, readingPurpose: .informational),
        "q28": Question(key: "q28", question: "你認為探索其他行星對人類有什麼意義？", type: "mc", answer: "D. 可以增進對宇宙的認識，尋找資源，並可能發現其他生命形式", choices: ["A. 沒有意義", "B. 只是浪費錢", "C. 很危險", "D. 可以增進對宇宙的認識，尋找資源，並可能發現其他生命形式"], explantation: ["探索其他行星可以增進對宇宙的認識，尋找資源，並可能發現其他生命形式，這對人類發展有重要意義"], pirlsProcess: .evaluating, difficultyLevel: 6, readingPurpose: .informational),
        
        // ========== PASSAGE 8: 傳統節日 (Informational, P4-P5) ==========
        "q29": Question(key: "q29", question: "文章中提到，春節最重要的傳統活動是什麼？", type: "mc", answer: "A. 家人團聚、吃年夜飯和拜年", choices: ["A. 家人團聚、吃年夜飯和拜年", "B. 看電視", "C. 睡覺", "D. 工作"], explantation: ["文章明確說明春節最重要的傳統活動是家人團聚、吃年夜飯和拜年"], pirlsProcess: .retrieving, difficultyLevel: 4, readingPurpose: .informational),
        "q30": Question(key: "q30", question: "從文中可以推測，為什麼傳統節日對人們很重要？", type: "mc", answer: "B. 因為它們傳承文化，增進家庭感情，並帶來歡樂", choices: ["A. 因為可以放假", "B. 因為它們傳承文化，增進家庭感情，並帶來歡樂", "C. 因為可以吃很多東西", "D. 沒有原因"], explantation: ["根據文章內容，傳統節日對人們重要是因為它們傳承文化、增進家庭感情並帶來歡樂"], pirlsProcess: .inferring, difficultyLevel: 5, readingPurpose: .informational),
        "q31": Question(key: "q31", question: "文章描述傳統節日的意義，主要想說明什麼？", type: "mc", answer: "C. 傳統節日是文化傳承的重要載體，具有深遠的社會意義", choices: ["A. 節日只是放假", "B. 節日不重要", "C. 傳統節日是文化傳承的重要載體，具有深遠的社會意義", "D. 節日很無聊"], explantation: ["文章通過描述傳統節日的意義，說明它們是文化傳承的重要載體，具有深遠的社會意義"], pirlsProcess: .interpreting, difficultyLevel: 5, readingPurpose: .informational),
        "q32": Question(key: "q32", question: "你認為在現代社會中，如何更好地傳承傳統節日文化？", type: "mc", answer: "D. 結合現代元素，讓年輕人參與，並在學校和家庭中傳授節日知識", choices: ["A. 不需要傳承", "B. 完全改變傳統", "C. 只讓老人參與", "D. 結合現代元素，讓年輕人參與，並在學校和家庭中傳授節日知識"], explantation: ["更好地傳承傳統節日文化需要結合現代元素，讓年輕人參與，並在學校和家庭中傳授節日知識"], pirlsProcess: .evaluating, difficultyLevel: 5, readingPurpose: .informational),
        
        // ========== PASSAGE 9: 學校的回收日 (Informational, P2-P3) ==========
        "q33": Question(key: "q33", question: "文中提到，學校舉辦回收日活動時，第一步通常要做什麼？", type: "mc", answer: "B. 分類紙類、塑膠與金屬，並清洗乾淨", choices: ["A. 直接把垃圾丟進大垃圾桶", "B. 分類紙類、塑膠與金屬，並清洗乾淨", "C. 把回收物藏在教室裡", "D. 等到放學才處理"], explantation: ["文章說明同學先把回收物分類並清洗，再送到回收區"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .informational),
        "q34": Question(key: "q34", question: "從文中可以推測，如果沒有先分類，最可能造成什麼問題？", type: "mc", answer: "C. 回收廠難以再利用，浪費資源", choices: ["A. 老師會提早下課", "B. 操場會變大", "C. 回收廠難以再利用，浪費資源", "D. 天氣會變冷"], explantation: ["未分類的混合物會讓回收處理困難，降低再利用效率"], pirlsProcess: .inferring, difficultyLevel: 3, readingPurpose: .informational),
        "q35": Question(key: "q35", question: "文章描述學校回收日的流程，主要想告訴讀者什麼？", type: "mc", answer: "A. 正確分類與合作，能讓環保行動更有效果", choices: ["A. 正確分類與合作，能讓環保行動更有效果", "B. 回收活動只是玩遊戲", "C. 學校不需要做環保", "D. 只有老師需要分類"], explantation: ["全文透過流程說明「分類＋合作」讓環保真正發揮作用"], pirlsProcess: .interpreting, difficultyLevel: 3, readingPurpose: .informational),
        "q36": Question(key: "q36", question: "你認為在班級裡推動回收，哪一項做法最有幫助？", type: "mc", answer: "D. 訂定簡單規則、互相提醒，並固定檢查分類是否正確", choices: ["A. 完全不提醒同學", "B. 把回收物混在同一袋", "C. 只在考試那天回收", "D. 訂定簡單規則、互相提醒，並固定檢查分類是否正確"], explantation: ["規則、提醒與檢查能讓習慣延續，是班級推動回收的關鍵"], pirlsProcess: .evaluating, difficultyLevel: 3, readingPurpose: .informational)
    ]

    // MARK: - Fetch Questions with Fallback Chain: Alibaba ECS -> Local
    func fetchQuestions(forSchoolID schoolID: String, completion: @escaping (Bool) -> Void) {
        // ✅ Try Alibaba ECS first
        guard let url = QuestionBankAPI.schoolQuestionsURL(forSchoolID: schoolID) else {
            print("⚠️ Invalid Alibaba ECS URL, using local questions.")
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let fetchedQuestions = try? JSONDecoder().decode([Question].self, from: data) else {
                // ✅ Fallback to local questions
                print("⚠️ Alibaba ECS failed, using local questions.")
                completion(false)
                return
            }

            DispatchQueue.main.async {
                self?.questions = fetchedQuestions
                print("✅ Successfully fetched questions from Alibaba ECS")
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
    
    /// Aggregates PIRLS process counts, difficulty levels, and reading purpose for content QA (also logged in DEBUG from `GameScene`).
    func buildCoverageReport() -> QuestionBankCoverageReport {
        let questions = Array(localQuestions.values)
        var pirlsCounts: [PIRLSProcess: Int] = [:]
        for p in PIRLSProcess.allCases { pirlsCounts[p] = 0 }
        var difficultyHistogram: [Int: Int] = [:]
        var purposeCounts: [ReadingPurpose: Int] = [.literary: 0, .informational: 0]
        for q in questions {
            if let proc = q.pirlsProcess {
                pirlsCounts[proc, default: 0] += 1
            }
            if let d = q.difficultyLevel {
                difficultyHistogram[d, default: 0] += 1
            }
            if let rp = q.readingPurpose {
                purposeCounts[rp, default: 0] += 1
            }
        }
        return QuestionBankCoverageReport(
            totalQuestions: questions.count,
            passageCount: passageSets.count,
            pirlsCounts: pirlsCounts,
            difficultyHistogram: difficultyHistogram,
            readingPurposeCounts: purposeCounts
        )
    }
    
    func getPassageForQuestion(_ questionKey: String) -> String? {
        for (_, passageSet) in passageSets {
            if passageSet.questionKeys.contains(questionKey) {
                return passageSet.passage
            }
        }
        return nil
    }
    
    /// Resolves `passageKey` (e.g. `passage3`) for analytics / answer logs.
    func passageKey(matchingPassageText text: String) -> String? {
        let norm = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for (_, set) in passageSets {
            if set.passage.trimmingCharacters(in: .whitespacesAndNewlines) == norm {
                return set.passageKey
            }
        }
        return nil
    }
    
    func getFullQuestion(forKey questionKey: String) -> String? {
        return localQuestions[questionKey]?.question
    }
    
    // MARK: - PIRLS Question Enrichment
    func enrichQuestionWithPIRLS(_ question: Question, passageText: String) -> Question {
        var enrichedQuestion = question
        
        // Auto-classify PIRLS process if not set (using enhanced classification)
        if enrichedQuestion.pirlsProcess == nil {
            // Use enhanced classification with answer for better accuracy
            let (process, _) = PIRLSQuestionClassifier.classifyQuestionEnhanced(
                question.question,
                passageText: passageText,
                answer: question.answer
            )
            enrichedQuestion.pirlsProcess = process
        }
        
        // Auto-classify reading purpose if not set
        if enrichedQuestion.readingPurpose == nil {
            enrichedQuestion.readingPurpose = PIRLSQuestionClassifier.classifyReadingPurpose(passageText)
        }
        
        // Extract vocabulary if not set (using enhanced extraction with difficulty level)
        if enrichedQuestion.vocabularyWords == nil || enrichedQuestion.vocabularyWords?.isEmpty == true {
            // Use enhanced extraction with difficulty level if available
            let difficulty = enrichedQuestion.difficultyLevel ?? estimateDifficultyLevel(question: question, passageText: passageText)
            let enhancedVocab = PIRLSQuestionClassifier.extractKeyVocabularyEnhanced(
                passageText,
                maxWords: 15,
                difficultyLevel: difficulty
            )
            enrichedQuestion.vocabularyWords = enhancedVocab.map { $0.word }
        }
        
        // Set default difficulty level if not set (based on question complexity)
        if enrichedQuestion.difficultyLevel == nil {
            enrichedQuestion.difficultyLevel = estimateDifficultyLevel(question: question, passageText: passageText)
        }
        
        return enrichedQuestion
    }
    
    private func estimateDifficultyLevel(question: Question, passageText: String) -> Int {
        // Simple heuristic: longer passages and complex questions = higher level
        let passageLength = passageText.count
        let questionLength = question.question.count
        
        if passageLength < 200 && questionLength < 30 {
            return 1  // Primary 1
        } else if passageLength < 400 && questionLength < 50 {
            return 2  // Primary 2
        } else if passageLength < 600 && questionLength < 70 {
            return 3  // Primary 3
        } else if passageLength < 800 {
            return 4  // Primary 4
        } else if passageLength < 1000 {
            return 5  // Primary 5
        } else {
            return 6  // Primary 6
        }
    }
}

struct Question: Codable {
    let key: String
    let question: String
    let type: String  // "mc" for multiple choice, "qa" for open-ended
    let answer: String
    let choices: [String]?  // Optional for multiple-choice questions
    let explantation: [String]?
    
    // MARK: - PIRLS Framework Fields
    var pirlsProcess: PIRLSProcess?  // PIRLS reading comprehension process
    var difficultyLevel: Int?  // 1-6 for primary levels
    var readingPurpose: ReadingPurpose?  // Literary or informational
    var vocabularyWords: [String]?  // Key vocabulary in passage
    
    // MARK: - Coding Keys for Backward Compatibility
    enum CodingKeys: String, CodingKey {
        case key, question, type, answer, choices, explantation
        case pirlsProcess, difficultyLevel, readingPurpose, vocabularyWords
    }
    
    // MARK: - Custom Decoder for Backward Compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        question = try container.decode(String.self, forKey: .question)
        type = try container.decode(String.self, forKey: .type)
        answer = try container.decode(String.self, forKey: .answer)
        choices = try container.decodeIfPresent([String].self, forKey: .choices)
        explantation = try container.decodeIfPresent([String].self, forKey: .explantation)
        
        // Optional PIRLS fields
        pirlsProcess = try container.decodeIfPresent(PIRLSProcess.self, forKey: .pirlsProcess)
        difficultyLevel = try container.decodeIfPresent(Int.self, forKey: .difficultyLevel)
        readingPurpose = try container.decodeIfPresent(ReadingPurpose.self, forKey: .readingPurpose)
        vocabularyWords = try container.decodeIfPresent([String].self, forKey: .vocabularyWords)
    }
    
    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(question, forKey: .question)
        try container.encode(type, forKey: .type)
        try container.encode(answer, forKey: .answer)
        try container.encodeIfPresent(choices, forKey: .choices)
        try container.encodeIfPresent(explantation, forKey: .explantation)
        try container.encodeIfPresent(pirlsProcess, forKey: .pirlsProcess)
        try container.encodeIfPresent(difficultyLevel, forKey: .difficultyLevel)
        try container.encodeIfPresent(readingPurpose, forKey: .readingPurpose)
        try container.encodeIfPresent(vocabularyWords, forKey: .vocabularyWords)
    }
    
    // MARK: - Convenience Initializer
    init(key: String, question: String, type: String, answer: String, choices: [String]? = nil, explantation: [String]? = nil, pirlsProcess: PIRLSProcess? = nil, difficultyLevel: Int? = nil, readingPurpose: ReadingPurpose? = nil, vocabularyWords: [String]? = nil) {
        self.key = key
        self.question = question
        self.type = type
        self.answer = answer
        self.choices = choices
        self.explantation = explantation
        self.pirlsProcess = pirlsProcess
        self.difficultyLevel = difficultyLevel
        self.readingPurpose = readingPurpose
        self.vocabularyWords = vocabularyWords
    }
}

struct PassageQuestionSet {
    let passageKey: String
    let passage: String
    let questionKeys: [String]
}

/// Snapshot of local question bank balance (PIRLS / difficulty / purpose).
struct QuestionBankCoverageReport {
    let totalQuestions: Int
    let passageCount: Int
    let pirlsCounts: [PIRLSProcess: Int]
    let difficultyHistogram: [Int: Int]
    let readingPurposeCounts: [ReadingPurpose: Int]
    
    var pirlsCountsDescription: String {
        PIRLSProcess.allCases.map { "\($0.rawValue): \(pirlsCounts[$0] ?? 0)" }.joined(separator: ", ")
    }
}

let passageSets = [
    // ========== PASSAGE 1: 小兔子的派對 (Literary, P1-P2) ==========
    "p1": PassageQuestionSet(
        passageKey: "passage1",
        passage: """
        星期六早晨，當第一縷溫暖的陽光灑落在綠油油的草坪上，小兔子樂樂就興奮地開始忙碌起來。\n從小櫃子裡取出五彩繽紛的氣球和彩帶，精心佈置著自己的花園。\n樂樂一邊掛著裝飾，一邊把自己親手製作的邀請函貼在大樹的小信箱上，希望能邀請到所有好朋友參加派對。不久，派對的鐘聲響起。花園裡，輕盈的小鳥在枝頭嬉戲，活潑的松鼠在樹間跳躍，而溫柔的小鹿也悄悄走近。\n樂樂熱情地迎接每一位來訪的朋友，大家圍在一起分享自製的胡蘿蔔蛋糕與新鮮果汁，歡笑聲和歡呼聲此起彼伏。隨著午後陽光逐漸變得柔和，派對也進入了尾聲。\n朋友們依依不捨地告別，約定下次還要聚在一起玩耍。\n樂樂站在花園中央，看著漸暗的天幕，心中滿懷著回憶與對未來派對的期待。\n回到家後，樂樂細細回味這一天的點滴，心裡暗自決定：下次，他要邀請更多的朋友，一同把這份快樂延續下去。
        """,
        questionKeys: ["q1", "q2", "q3", "q4"]
    ),
    
    // ========== PASSAGE 2: 四季變化 (Informational, P2-P3) ==========
    "p2": PassageQuestionSet(
        passageKey: "passage2",
        passage: """
        一年有四個季節，每一個季節都有它獨特的風景與氣息。\n春天來臨時，萬物開始甦醒，百花齊放，溫柔的春風拂過大地。人們喜歡到公園踏青、賞花和放風箏，感受大自然的生機勃勃。\n夏日陽光燦爛，氣溫漸高。小朋友們在泳池中嬉戲，樹下乘涼的人們則享受著冰涼的飲料。果樹上成熟的果實散發著誘人的香甜味，讓這個季節充滿熱情與活力。\n到了秋天，樹葉漸轉為金黃和火紅，農田裡傳來豐收的忙碌聲。農民們忙於收割稻穀，果園中傳來陣陣果香，秋天彷彿在向人們展示一幅多彩的畫卷。\n冬天則帶來寒冷和靜謐，大地被皚皚白雪覆蓋。人們穿上厚重衣物在雪地上堆雪人、滑雪，享受著冬日獨有的樂趣。\n四季更替，不僅改變了自然景觀，也豐富了人們的生活，讓我們每個月都能感受到不一樣的驚喜與故事。
        """,
        questionKeys: ["q5", "q6", "q7", "q8"]
    ),
    
    // ========== PASSAGE 3: 小鳥的遷徙 (Informational, P3-P4) ==========
    "p3": PassageQuestionSet(
        passageKey: "passage3",
        passage: """
        每年秋天，數以萬計的小鳥開始了它們的長途遷徙之旅。這些勇敢的旅行者從寒冷的北方出發，飛向溫暖的南方，尋找更適合的氣候和豐富的食物。\n遷徙是一項艱鉅的任務。小鳥們需要飛行數千公里，跨越山川、河流和海洋。在飛行過程中，它們必須依靠太陽、星星和地球的磁場來導航，確保不會迷失方向。\n天氣變化是遷徙中最大的挑戰。強風、暴雨和濃霧都可能阻礙小鳥的飛行。然而，這些小鳥展現出驚人的適應能力，它們會調整飛行高度和路線，避開惡劣天氣。\n遷徙不僅是為了生存，也是鳥類生命週期中的重要環節。通過遷徙，鳥類能夠在不同的季節找到最適合繁殖和覓食的地方，這使得它們能夠在地球上各個角落繁衍生息。\n科學家們通過觀察和研究鳥類的遷徙行為，不僅了解了鳥類的生存智慧，也為保護這些美麗的生物提供了重要的科學依據。
        """,
        questionKeys: ["q9", "q10", "q11", "q12"]
    ),
    
    // ========== PASSAGE 4: 小貓咪的冒險 (Literary, P2-P3) ==========
    "p4": PassageQuestionSet(
        passageKey: "passage4",
        passage: """
        小貓咪咪咪一直住在溫暖舒適的家裡，每天都有主人準備的美味食物和柔軟的床鋪。然而，咪咪心中總是充滿了對外面世界的好奇。\n有一天，咪咪趁著主人不注意，悄悄地溜出了家門。外面的世界對咪咪來說既新奇又陌生。它看到了高大的樹木、美麗的花朵，還遇到了一隻友善的小狗。小狗告訴咪咪，外面的世界雖然有趣，但也充滿了未知的危險。\n咪咪在探索的過程中，經歷了許多有趣的冒險。它爬上了一棵大樹，看到了遠處的風景；它追趕蝴蝶，感受到了自由奔跑的快樂。然而，隨著天色漸暗，咪咪開始想念家裡的溫暖。\n當咪咪回到家時，主人正焦急地等待著。看到咪咪安全歸來，主人既高興又擔心。咪咪依偎在主人懷裡，心中充滿了對家的感激。從那天起，咪咪明白了，雖然外面的世界很精彩，但家永遠是最溫暖、最安全的地方。
        """,
        questionKeys: ["q13", "q14", "q15", "q16"]
    ),
    
    // ========== PASSAGE 5: 植物的生長 (Informational, P3-P4) ==========
    "p5": PassageQuestionSet(
        passageKey: "passage5",
        passage: """
        植物是地球上最重要的生物之一，它們通過光合作用將陽光轉化為能量，為整個生態系統提供基礎。植物的生長過程是一個複雜而神奇的過程。\n植物生長需要幾個基本條件：陽光、水分、土壤和空氣。陽光為植物提供能量，使它們能夠進行光合作用；水分幫助植物運輸養分；土壤提供植物所需的礦物質；空氣中的二氧化碳則是光合作用的重要原料。\n從種子發芽到長成參天大樹，植物的生長經歷了多個階段。首先是種子發芽，小小的種子在適宜的條件下會長出根和芽。接著，植物會長出葉子，開始進行光合作用。隨著時間的推移，植物會不斷長高長大，開花結果，完成生命的循環。\n不同的植物有不同的生長速度和需求。有些植物喜歡充足的陽光，有些則喜歡陰涼的環境；有些需要大量的水分，有些則耐旱。了解植物的生長需求，可以幫助我們更好地照顧它們，讓它們健康成長。
        """,
        questionKeys: ["q17", "q18", "q19", "q20"]
    ),
    
    // ========== PASSAGE 6: 小明的圖書館之旅 (Literary, P4-P5) ==========
    "p6": PassageQuestionSet(
        passageKey: "passage6",
        passage: """
        小明是一個活潑好動的小男孩，他對很多事情都充滿好奇，但唯獨對閱讀沒有興趣。他覺得書本很無聊，寧願在外面玩耍也不願意靜下心來讀書。\n有一天，小明的媽媽帶他去了市立圖書館。這是小明第一次走進圖書館，他被眼前的一切震撼了。書架上排列著成千上萬本書，各種各樣的書籍整齊地擺放著，從童話故事到科學知識，從歷史傳記到藝術欣賞，應有盡有。\n圖書館裡很安靜，許多人都專注地閱讀著。小明看到一個小女孩正在讀一本關於恐龍的書，臉上露出興奮的表情；還有一位老爺爺在讀歷史書籍，不時點頭思考。\n圖書館員阿姨看到小明，親切地問他喜歡什麼。小明說他喜歡冒險故事，阿姨便推薦了幾本適合他年齡的冒險小說。小明抱著試試看的心態，翻開了第一本書。\n沒想到，小明很快就被書中的故事吸引了。他彷彿跟著主角一起冒險，經歷了各種驚險刺激的情節。從那天起，小明愛上了閱讀。他發現，書本可以帶他進入不同的世界，體驗各種各樣的人生。閱讀不僅豐富了他的知識，也開啟了他對世界的好奇心。
        """,
        questionKeys: ["q21", "q22", "q23", "q24"]
    ),
    
    // ========== PASSAGE 7: 太陽系的行星 (Informational, P5-P6) ==========
    "p7": PassageQuestionSet(
        passageKey: "passage7",
        passage: """
        太陽系是我們所在的宇宙家園，由太陽和圍繞它運行的八顆行星組成。每顆行星都有其獨特的特徵和環境條件，形成了豐富多彩的宇宙景觀。\n水星是距離太陽最近的行星，表面溫度極高，白天可達攝氏四百多度，但夜晚卻會降到零下一百多度。由於距離太陽太近，水星上沒有大氣層，表面布滿了隕石坑。\n金星被稱為地球的「姊妹星」，因為它們大小相似。然而，金星表面被厚厚的二氧化碳大氣層覆蓋，產生了強烈的溫室效應，使得表面溫度高達攝氏四百多度，是太陽系中最熱的行星。\n地球是我們的家園，是太陽系中唯一已知有生命存在的行星。地球有適宜的溫度、液態水和保護生命的大氣層，這些條件使得生命得以繁衍生息。\n火星被稱為「紅色星球」，因為其表面富含氧化鐵，呈現出紅色。科學家們一直在探索火星，希望找到生命存在的證據。\n木星是太陽系中最大的行星，是一個巨大的氣體行星。它有明顯的條紋和大紅斑，這是其大氣層中的風暴系統。\n土星以其美麗的光環而聞名，這些光環主要由冰粒和岩石碎片組成。\n天王星和海王星是距離太陽最遠的行星，它們都是冰巨星，表面溫度極低。\n通過研究這些行星，我們不僅了解了太陽系的形成和演化，也為尋找其他可能適合生命存在的星球提供了重要線索。
        """,
        questionKeys: ["q25", "q26", "q27", "q28"]
    ),
    
    // ========== PASSAGE 8: 傳統節日 (Informational, P4-P5) ==========
    "p8": PassageQuestionSet(
        passageKey: "passage8",
        passage: """
        傳統節日是文化傳承的重要載體，它們不僅是時間的標記，更是人們情感交流和文化認同的重要時刻。在中國，有許多重要的傳統節日，每個節日都有其獨特的意義和慶祝方式。\n春節是中國最重要的傳統節日，象徵著新年的開始。在這個節日裡，家人會團聚在一起，共享年夜飯，這是一年中最豐盛的一餐。孩子們會收到壓歲錢，這是長輩對晚輩的祝福。人們還會貼春聯、放鞭炮、舞龍舞獅，營造出熱鬧喜慶的氛圍。春節不僅是家庭團聚的時刻，也是人們表達對新一年美好願望的時刻。\n中秋節是另一個重要的傳統節日，象徵著團圓和豐收。在這一天，人們會賞月、吃月餅，表達對家人的思念和對美好生活的嚮往。月餅的圓形象徵著團圓，而明亮的月亮則象徵著人們對親人的思念。\n端午節是為了紀念古代詩人屈原而設立的節日。在這一天，人們會划龍舟、吃粽子，這些活動不僅是對歷史的紀念，也是對傳統文化的傳承。\n這些傳統節日不僅豐富了人們的生活，也傳承了深厚的文化底蘊。它們讓不同世代的人們能夠共同參與，分享共同的價值觀和文化認同。在現代社會中，雖然生活方式發生了變化，但傳統節日的核心意義依然重要，它們提醒我們不忘根本，珍惜文化傳統。
        """,
        questionKeys: ["q29", "q30", "q31", "q32"]
    ),
    
    // ========== PASSAGE 9: 學校的回收日 (Informational, P2-P3) ==========
    "p9": PassageQuestionSet(
        passageKey: "passage9",
        passage: """
        每個月第一個星期五，陽光小學都會舉辦「回收日」。\n早上，環保小老師會在走廊上示範：先把寶特瓶沖洗乾淨、壓扁，再把紙箱拆平、繩子綁好；塑膠袋要抖掉食物殘渣，金屬罐則要擦乾，避免生鏽。\n同學們分組合作，有人負責檢查分類是否正確，有人推著小推車把回收物送到校門口的集中區。老師提醒大家：「分類愈清楚，回收廠愈容易把資源變成新產品。」\n活動結束後，各班會記錄回收重量，並在朝會分享成果。大家發現，只要多一點耐心與合作，小小的動作也能減少垃圾、愛護地球。
        """,
        questionKeys: ["q33", "q34", "q35", "q36"]
    )
]
