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
        "q4": Question(key: "q4", question: "根據文中派對的佈置與活動，下列哪一項判斷最有根據？", type: "mc", answer: "B. 氣球、彩帶與分享點心，一起營造了熱鬧氣氛", choices: ["A. 派對一定很安靜，因為沒有人說話", "B. 氣球、彩帶與分享點心，一起營造了熱鬧氣氛", "C. 朋友們全程都在打掃花園", "D. 樂樂從頭到尾都獨自待在房間"], explantation: ["文中寫樂樂掛氣球彩帶，並與朋友分享蛋糕果汁、歡笑聲此起彼伏，故 B 最有根據"], pirlsProcess: .evaluating, difficultyLevel: 2, readingPurpose: .literary),
        
        // ========== PASSAGE 2: 四季變化 (Informational, P2-P3) ==========
        "q5": Question(key: "q5", question: "文章中提到，一年有哪四個季節？", type: "mc", answer: "A. 春、夏、秋、冬", choices: ["A. 春、夏、秋、冬", "B. 春、夏、雨、冬", "C. 春、秋、夏、風", "D. 夏、秋、冬、雪"], explantation: ["文章中提到的一年四季為：春、夏、秋、冬"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .informational),
        "q6": Question(key: "q6", question: "根據文章，春天和秋天各自的主要特徵為何？", type: "mc", answer: "B. 春天萬物甦醒賞花，秋天樹葉變色、豐收在望", choices: ["A. 春天寒冷，秋天炎熱", "B. 春天萬物甦醒賞花，秋天樹葉變色、豐收在望","C. 春天下雪，秋天出現霧氣","D. 春天熱鬧，秋天寧靜"], explantation: ["春天萬物甦醒、賞花，秋天樹葉變色、豐收在望"], pirlsProcess: .interpreting, difficultyLevel: 3, readingPurpose: .informational),
        "q7": Question(key: "q7", question: "作者認為四季變化能帶來驚喜，最可能的原因是：", type: "mc", answer: "A. 每個季節都有不同的天氣和活動", choices: ["A. 每個季節都有不同的天氣和活動", "B. 每個季節都非常相似", "C. 四季變化只影響植物生長", "D. 四季變化使人感到困惑"], explantation: ["作者指出因為每個季節都有不同的天氣與活動，故季節變化總能帶來驚喜"], pirlsProcess: .inferring, difficultyLevel: 3, readingPurpose: .informational),
        "q8": Question(key: "q8", question: "根據文中對四季的描述，下列哪一項說法最能得到文章支持？", type: "mc", answer: "B. 各季節有不同天氣與活動，因此生活體驗也會跟著改變", choices: ["A. 四季的天氣與活動幾乎完全相同", "B. 各季節有不同天氣與活動，因此生活體驗也會跟著改變", "C. 只有冬天會影響人們的生活", "D. 文章主張大家應忽略季節變化"], explantation: ["文中分別寫春夏秋冬的景色與活動，並說四季豐富生活，故 B 最有根據"], pirlsProcess: .evaluating, difficultyLevel: 3, readingPurpose: .informational),
        
        // ========== PASSAGE 3: 小鳥的遷徙 (Informational, P3-P4) ==========
        "q9": Question(key: "q9", question: "文章中提到，小鳥為什麼要遷徙？", type: "mc", answer: "A. 為了尋找更適合的氣候和食物", choices: ["A. 為了尋找更適合的氣候和食物", "B. 因為他們喜歡旅行", "C. 為了逃避天敵", "D. 因為他們迷路了"], explantation: ["文章明確說明小鳥遷徙是為了尋找更適合的氣候和食物"], pirlsProcess: .retrieving, difficultyLevel: 3, readingPurpose: .informational),
        "q10": Question(key: "q10", question: "從文中可以推測，小鳥在遷徙過程中面臨的最大挑戰是什麼？", type: "mc", answer: "C. 長途飛行需要大量體力和面對天氣變化", choices: ["A. 找不到同伴", "B. 不知道方向", "C. 長途飛行需要大量體力和面對天氣變化", "D. 沒有地方休息"], explantation: ["文中提到小鳥需要飛行數千公里，並要面對各種天氣變化，這是最主要的挑戰"], pirlsProcess: .inferring, difficultyLevel: 4, readingPurpose: .informational),
        "q11": Question(key: "q11", question: "文章描述小鳥遷徙的過程，主要想說明什麼？", type: "mc", answer: "B. 遷徙是鳥類適應環境的重要生存策略", choices: ["A. 小鳥很聰明", "B. 遷徙是鳥類適應環境的重要生存策略", "C. 遷徙很危險", "D. 小鳥喜歡冒險"], explantation: ["文章通過描述遷徙過程，說明這是鳥類適應環境變化的重要生存策略"], pirlsProcess: .interpreting, difficultyLevel: 4, readingPurpose: .informational),
        "q12": Question(key: "q12", question: "根據文中對遷徙需求與研究目的的說明，下列哪一項保護作法最能對應文章重點？", type: "mc", answer: "D. 保護棲息環境並運用研究結果協助保育", choices: ["A. 捕捉遷徙鳥類以便就近觀察", "B. 設法阻止鳥類長途飛行", "C. 認為遷徙與環境無關，不必保護", "D. 保護棲息環境並運用研究結果協助保育"], explantation: ["文中強調氣候、食物與科學家研究可提供保護依據，故保護棲息並善用研究最能對應文章"], pirlsProcess: .evaluating, difficultyLevel: 4, readingPurpose: .informational),
        
        // ========== PASSAGE 4: 小貓咪的冒險 (Literary, P2-P3) ==========
        "q13": Question(key: "q13", question: "小貓咪第一次離開家時，遇到了什麼？", type: "mc", answer: "A. 一隻友善的小狗", choices: ["A. 一隻友善的小狗", "B. 一隻兇猛的老虎", "C. 一隻會飛的鳥", "D. 一條河流"], explantation: ["文中提到小貓咪第一次離開家時遇到了一隻友善的小狗"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .literary),
        "q14": Question(key: "q14", question: "從故事中可以推測，小貓咪為什麼決定回家？", type: "mc", answer: "B. 它想念家人，也意識到家的溫暖", choices: ["A. 因為外面太危險", "B. 它想念家人，也意識到家的溫暖", "C. 因為迷路了", "D. 因為肚子餓了"], explantation: ["從故事中可以看出，小貓咪在冒險後想念家人，意識到家的溫暖"], pirlsProcess: .inferring, difficultyLevel: 3, readingPurpose: .literary),
        "q15": Question(key: "q15", question: "這個故事想要告訴讀者什麼道理？", type: "mc", answer: "C. 家是最溫暖的地方，冒險後總會想回家", choices: ["A. 不要離開家", "B. 外面很危險", "C. 家是最溫暖的地方，冒險後總會想回家", "D. 小貓咪很勇敢"], explantation: ["故事通過小貓咪的冒險經歷，傳達了家是最溫暖的地方這個道理"], pirlsProcess: .interpreting, difficultyLevel: 3, readingPurpose: .literary),
        "q16": Question(key: "q16", question: "根據故事結尾咪咪的感受，下列哪一項評價最有文中依據？", type: "mc", answer: "D. 外面世界精彩，但家仍是最溫暖安全的地方", choices: ["A. 咪咪從此再也不想出門", "B. 咪咪覺得家一點也不重要", "C. 咪咪認為外面完全沒有危險", "D. 外面世界精彩，但家仍是最溫暖安全的地方"], explantation: ["結尾寫咪咪明白外面精彩，但家永遠最溫暖安全，故 D 最有依據"], pirlsProcess: .evaluating, difficultyLevel: 3, readingPurpose: .literary),
        
        // ========== PASSAGE 5: 植物的生長 (Informational, P3-P4) ==========
        "q17": Question(key: "q17", question: "文章中提到，植物生長需要哪些基本條件？", type: "mc", answer: "A. 陽光、水分、土壤和空氣", choices: ["A. 陽光、水分、土壤和空氣", "B. 只有陽光", "C. 只有水分", "D. 不需要任何條件"], explantation: ["文章明確說明植物生長需要陽光、水分、土壤和空氣"], pirlsProcess: .retrieving, difficultyLevel: 3, readingPurpose: .informational),
        "q18": Question(key: "q18", question: "從文中可以推測，為什麼有些植物長得比其他植物快？", type: "mc", answer: "B. 因為它們獲得了更充足的陽光、水分和養分", choices: ["A. 因為它們比較聰明", "B. 因為它們獲得了更充足的陽光、水分和養分", "C. 因為它們比較大", "D. 沒有原因"], explantation: ["根據文章內容，植物生長速度取決於獲得的陽光、水分和養分是否充足"], pirlsProcess: .inferring, difficultyLevel: 4, readingPurpose: .informational),
        "q19": Question(key: "q19", question: "文章描述植物生長的過程，主要想說明什麼？", type: "mc", answer: "C. 植物生長是一個需要多種條件配合的複雜過程", choices: ["A. 植物很容易生長", "B. 植物不需要照顧", "C. 植物生長是一個需要多種條件配合的複雜過程", "D. 所有植物都一樣"], explantation: ["文章通過描述植物生長需要的各種條件，說明這是一個複雜的過程"], pirlsProcess: .interpreting, difficultyLevel: 4, readingPurpose: .informational),
        "q20": Question(key: "q20", question: "根據文中所列生長條件，下列哪一項照顧方式最符合文章說明？", type: "mc", answer: "D. 依植物需求提供適當陽光、水分與養分，並觀察生長", choices: ["A. 每天大量澆水，不管植物種類", "B. 把所有植物都放在完全不見光處", "C. 認為植物完全不需要任何照顧", "D. 依植物需求提供適當陽光、水分與養分，並觀察生長"], explantation: ["文章強調陽光、水分、土壤、空氣與不同需求，故依需求適當照顧最符合說明"], pirlsProcess: .evaluating, difficultyLevel: 4, readingPurpose: .informational),
        
        // ========== PASSAGE 6: 小明的圖書館之旅 (Literary, P4-P5) ==========
        "q21": Question(key: "q21", question: "小明第一次去圖書館時，最吸引他的是什麼？", type: "mc", answer: "B. 書架上排列整齊的各種書籍", choices: ["A. 圖書館的建築", "B. 書架上排列整齊的各種書籍", "C. 圖書館的椅子", "D. 圖書館的燈光"], explantation: ["文中提到小明被書架上排列整齊的各種書籍所吸引"], pirlsProcess: .retrieving, difficultyLevel: 4, readingPurpose: .literary),
        "q22": Question(key: "q22", question: "從故事中可以推測，小明為什麼會愛上閱讀？", type: "mc", answer: "C. 因為他發現書本可以帶他進入不同的世界", choices: ["A. 因為老師要求", "B. 因為父母要求", "C. 因為他發現書本可以帶他進入不同的世界", "D. 因為沒有其他事情做"], explantation: ["從故事中可以看出，小明通過閱讀發現書本可以帶他進入不同的世界，因此愛上閱讀"], pirlsProcess: .inferring, difficultyLevel: 5, readingPurpose: .literary),
        "q23": Question(key: "q23", question: "這個故事想要傳達給讀者什麼訊息？", type: "mc", answer: "A. 閱讀可以開啟知識的大門，豐富我們的心靈", choices: ["A. 閱讀可以開啟知識的大門，豐富我們的心靈", "B. 圖書館很漂亮", "C. 小明很聰明", "D. 書本很重"], explantation: ["故事通過小明的經歷，傳達了閱讀可以開啟知識大門、豐富心靈的訊息"], pirlsProcess: .interpreting, difficultyLevel: 5, readingPurpose: .literary),
        "q24": Question(key: "q24", question: "根據小明在圖書館的轉變，下列哪一項對閱讀作用的評價最有文中依據？", type: "mc", answer: "D. 閱讀能帶他進入不同世界，並豐富知識與好奇心", choices: ["A. 閱讀對小明完全沒有幫助", "B. 閱讀只是被迫完成作業", "C. 閱讀讓小明對世界更沒興趣", "D. 閱讀能帶他進入不同世界，並豐富知識與好奇心"], explantation: ["文末寫書本帶他進入不同世界、豐富知識並開啟好奇心，故 D 最有依據"], pirlsProcess: .evaluating, difficultyLevel: 5, readingPurpose: .literary),
        
        // ========== PASSAGE 7: 太陽系的行星 (Informational, P5-P6) ==========
        "q25": Question(key: "q25", question: "文章中提到，太陽系中有幾顆行星？", type: "mc", answer: "A. 八顆", choices: ["A. 八顆", "B. 九顆", "C. 七顆", "D. 十顆"], explantation: ["文章明確說明太陽系中有八顆行星"], pirlsProcess: .retrieving, difficultyLevel: 5, readingPurpose: .informational),
        "q26": Question(key: "q26", question: "從文中可以推測，為什麼水星和金星表面溫度很高？", type: "mc", answer: "B. 因為它們距離太陽很近，接收大量太陽熱量", choices: ["A. 因為它們很大", "B. 因為它們距離太陽很近，接收大量太陽熱量", "C. 因為它們有火山", "D. 沒有原因"], explantation: ["根據文章內容，水星和金星距離太陽很近，因此接收大量太陽熱量，表面溫度很高"], pirlsProcess: .inferring, difficultyLevel: 6, readingPurpose: .informational),
        "q27": Question(key: "q27", question: "文章描述太陽系各行星的特徵，主要想說明什麼？", type: "mc", answer: "C. 每個行星都有其獨特的特徵和環境條件", choices: ["A. 所有行星都一樣", "B. 只有地球適合生命", "C. 每個行星都有其獨特的特徵和環境條件", "D. 行星沒有差異"], explantation: ["文章通過描述各行星的不同特徵，說明每個行星都有其獨特的環境條件"], pirlsProcess: .interpreting, difficultyLevel: 6, readingPurpose: .informational),
        "q28": Question(key: "q28", question: "根據文中對行星研究與探索的說明，下列哪一項判斷最能得到文章支持？", type: "mc", answer: "D. 研究行星有助了解太陽系，並尋找其他可能適合生命的線索", choices: ["A. 研究行星對認識宇宙毫無幫助", "B. 文章主張探索只會浪費資源", "C. 所有行星環境都與地球完全相同", "D. 研究行星有助了解太陽系，並尋找其他可能適合生命的線索"], explantation: ["文末指出研究行星可了解太陽系形成演化，並為尋找其他適合生命的星球提供線索"], pirlsProcess: .evaluating, difficultyLevel: 6, readingPurpose: .informational),
        
        // ========== PASSAGE 8: 傳統節日 (Informational, P4-P5) ==========
        "q29": Question(key: "q29", question: "文章中提到，春節最重要的傳統活動是什麼？", type: "mc", answer: "A. 家人團聚、吃年夜飯和拜年", choices: ["A. 家人團聚、吃年夜飯和拜年", "B. 看電視", "C. 睡覺", "D. 工作"], explantation: ["文章明確說明春節最重要的傳統活動是家人團聚、吃年夜飯和拜年"], pirlsProcess: .retrieving, difficultyLevel: 4, readingPurpose: .informational),
        "q30": Question(key: "q30", question: "從文中可以推測，為什麼傳統節日對人們很重要？", type: "mc", answer: "B. 因為它們傳承文化，增進家庭感情，並帶來歡樂", choices: ["A. 因為可以放假", "B. 因為它們傳承文化，增進家庭感情，並帶來歡樂", "C. 因為可以吃很多東西", "D. 沒有原因"], explantation: ["根據文章內容，傳統節日對人們重要是因為它們傳承文化、增進家庭感情並帶來歡樂"], pirlsProcess: .inferring, difficultyLevel: 5, readingPurpose: .informational),
        "q31": Question(key: "q31", question: "文章描述傳統節日的意義，主要想說明什麼？", type: "mc", answer: "C. 傳統節日是文化傳承的重要載體，具有深遠的社會意義", choices: ["A. 節日只是放假", "B. 節日不重要", "C. 傳統節日是文化傳承的重要載體，具有深遠的社會意義", "D. 節日很無聊"], explantation: ["文章通過描述傳統節日的意義，說明它們是文化傳承的重要載體，具有深遠的社會意義"], pirlsProcess: .interpreting, difficultyLevel: 5, readingPurpose: .informational),
        "q32": Question(key: "q32", question: "根據文中對現代生活與傳統節日的討論，下列哪一項作法最能呼應文章重點？", type: "mc", answer: "D. 在生活改變中仍珍惜並參與節日，讓不同世代共享文化意義", choices: ["A. 既然生活已改變，傳統節日就可完全取消", "B. 只保留放假，不必了解節日意義", "C. 節日只適合老人，年輕人不必參與", "D. 在生活改變中仍珍惜並參與節日，讓不同世代共享文化意義"], explantation: ["文中說生活方式改變，但節日核心意義仍重要，並讓不同世代共同參與，故 D 最呼應"], pirlsProcess: .evaluating, difficultyLevel: 5, readingPurpose: .informational),
        
        // ========== PASSAGE 9: 學校的回收日 (Informational, P2-P3) ==========
        "q33": Question(key: "q33", question: "文中提到，學校舉辦回收日活動時，第一步通常要做什麼？", type: "mc", answer: "B. 分類紙類、塑膠與金屬，並清洗乾淨", choices: ["A. 直接把垃圾丟進大垃圾桶", "B. 分類紙類、塑膠與金屬，並清洗乾淨", "C. 把回收物藏在教室裡", "D. 等到放學才處理"], explantation: ["文章說明同學先把回收物分類並清洗，再送到回收區"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .informational),
        "q34": Question(key: "q34", question: "從文中可以推測，如果沒有先分類，最可能造成什麼問題？", type: "mc", answer: "C. 回收廠難以再利用，浪費資源", choices: ["A. 老師會提早下課", "B. 操場會變大", "C. 回收廠難以再利用，浪費資源", "D. 天氣會變冷"], explantation: ["未分類的混合物會讓回收處理困難，降低再利用效率"], pirlsProcess: .inferring, difficultyLevel: 3, readingPurpose: .informational),
        "q35": Question(key: "q35", question: "文章描述學校回收日的流程，主要想告訴讀者什麼？", type: "mc", answer: "A. 正確分類與合作，能讓環保行動更有效果", choices: ["A. 正確分類與合作，能讓環保行動更有效果", "B. 回收活動只是玩遊戲", "C. 學校不需要做環保", "D. 只有老師需要分類"], explantation: ["全文透過流程說明「分類＋合作」讓環保真正發揮作用"], pirlsProcess: .interpreting, difficultyLevel: 3, readingPurpose: .informational),
        "q36": Question(key: "q36", question: "根據文中回收日的流程，下列哪一項班級做法最有文中依據？", type: "mc", answer: "D. 先正確分類並分工檢查，再集中送回收", choices: ["A. 不分類，直接全部混在一起", "B. 把回收物藏起來不送集中區", "C. 只在考試那天才做回收", "D. 先正確分類並分工檢查，再集中送回收"], explantation: ["文中寫清洗分類、有人檢查、再送到集中區，故 D 最有依據"], pirlsProcess: .evaluating, difficultyLevel: 3, readingPurpose: .informational),
        
        // ========== PASSAGE 10: 阿美的雨天日記 (Literary, P1) ==========
        "q37": Question(key: "q37", question: "阿美早上醒來時，窗外是什麼天氣？", type: "mc", answer: "A. 下著細雨", choices: ["A. 下著細雨", "B. 出大太陽", "C. 正在下雪", "D. 刮著大風沙"], explantation: ["文中寫阿美看見窗外下著細雨"], pirlsProcess: .retrieving, difficultyLevel: 1, readingPurpose: .literary),
        "q38": Question(key: "q38", question: "從日記可以推測，阿美後來為什麼覺得雨天也能開心？", type: "mc", answer: "B. 她換了方式在家畫畫、做小船，還看到彩虹", choices: ["A. 因為雨天可以去公園玩", "B. 她換了方式在家畫畫、做小船，還看到彩虹", "C. 因為她整天睡覺", "D. 因為媽媽帶她去游泳"], explantation: ["文中寫她畫畫、做小船，傍晚見彩虹，並寫雨天換方式也能開心"], pirlsProcess: .inferring, difficultyLevel: 1, readingPurpose: .literary),
        "q39": Question(key: "q39", question: "這篇日記主要想表達什麼想法？", type: "mc", answer: "C. 計畫改變時，換個做法仍可過得充實快樂", choices: ["A. 雨天一定很掃興", "B. 只能待在房間發呆", "C. 計畫改變時，換個做法仍可過得充實快樂", "D. 彩虹每天都會出現"], explantation: ["結尾點出雨天不一定掃興，換個方式也能開心"], pirlsProcess: .interpreting, difficultyLevel: 2, readingPurpose: .literary),
        "q40": Question(key: "q40", question: "根據日記內容，下列哪一項判斷最有根據？", type: "mc", answer: "B. 在家創作與觀察窗外變化，讓雨天變得有趣", choices: ["A. 阿美最後仍覺得雨天完全沒意思", "B. 在家創作與觀察窗外變化，讓雨天變得有趣", "C. 阿美整天都在外面奔跑", "D. 弟弟完全沒有參與任何活動"], explantation: ["文中有畫畫、做小船、看彩虹等細節支持 B"], pirlsProcess: .evaluating, difficultyLevel: 2, readingPurpose: .literary),
        
        // ========== PASSAGE 11: 操場上的接力賽 (Literary, P2) ==========
        "q41": Question(key: "q41", question: "接力賽是在哪兩個班級之間舉行？", type: "mc", answer: "A. 三年甲班和三年乙班", choices: ["A. 三年甲班和三年乙班", "B. 一年級和六年級", "C. 老師和家長", "D. 兩所不同學校"], explantation: ["文中明確寫三年甲班和三年乙班舉行接力賽"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .literary),
        "q42": Question(key: "q42", question: "從文中可以推測，小傑差點跌倒後仍繼續跑，最可能代表什麼？", type: "mc", answer: "C. 他雖然緊張或失誤，仍不肯放棄", choices: ["A. 他想立刻退出比賽", "B. 他故意摔倒給大家看", "C. 他雖然緊張或失誤，仍不肯放棄", "D. 他不知道比賽規則"], explantation: ["寫他差點跌倒卻立刻站穩繼續跑，並說下次會更穩，可見不放棄"], pirlsProcess: .inferring, difficultyLevel: 2, readingPurpose: .literary),
        "q43": Question(key: "q43", question: "老師的話在故事中主要想強調什麼？", type: "mc", answer: "B. 輸贏之外，彼此加油與不放棄更重要", choices: ["A. 只有第一名才值得鼓勵", "B. 輸贏之外，彼此加油與不放棄更重要", "C. 輸了的人不必再努力", "D. 接力賽不需要團隊合作"], explantation: ["老師說輸贏重要，但更重要的是彼此加油、不放棄"], pirlsProcess: .interpreting, difficultyLevel: 3, readingPurpose: .literary),
        "q44": Question(key: "q44", question: "根據比賽經過與結尾反應，下列哪一項評價最有文中依據？", type: "mc", answer: "D. 乙班雖惜敗仍為對手鼓掌，展現了運動精神", choices: ["A. 乙班輸了就對甲班生氣不理會", "B. 小傑跌倒後就放棄不再跑", "C. 老師只關心分數，不談加油", "D. 乙班雖惜敗仍為對手鼓掌，展現了運動精神"], explantation: ["文中寫乙班同學雖然輸了仍為對手鼓掌，故 D 最有依據"], pirlsProcess: .evaluating, difficultyLevel: 3, readingPurpose: .literary),
        
        // ========== PASSAGE 12: 認識地圖與方向 (Informational, P2-P3) ==========
        "q45": Question(key: "q45", question: "文章說明，地圖上方通常代表哪個方向？", type: "mc", answer: "A. 北方", choices: ["A. 北方", "B. 南方", "C. 東方", "D. 西方"], explantation: ["文中寫地圖上方通常代表北方"], pirlsProcess: .retrieving, difficultyLevel: 2, readingPurpose: .informational),
        "q46": Question(key: "q46", question: "從文中可以推測，為什麼看懂圖例對使用地圖很重要？", type: "mc", answer: "B. 因為圖例用符號標示地點，能幫助辨認學校、公園等位置", choices: ["A. 因為圖例只是裝飾圖案", "B. 因為圖例用符號標示地點，能幫助辨認學校、公園等位置", "C. 因為沒有圖例也能隨便猜", "D. 因為圖例只說明天氣"], explantation: ["文中說圖例用符號標示學校、公園、車站，故辨認地點需要圖例"], pirlsProcess: .inferring, difficultyLevel: 3, readingPurpose: .informational),
        "q47": Question(key: "q47", question: "文章介紹地圖用法，主要想說明什麼？", type: "mc", answer: "C. 掌握方向、圖例與比例尺，有助規劃路線、避免迷路", choices: ["A. 地圖只能用來畫畫", "B. 外出完全不需要地圖", "C. 掌握方向、圖例與比例尺，有助規劃路線、避免迷路", "D. 比例尺與找路無關"], explantation: ["全文說明方向、圖例、比例尺與規劃路線，強調學會看地圖就不容易迷路"], pirlsProcess: .interpreting, difficultyLevel: 3, readingPurpose: .informational),
        "q48": Question(key: "q48", question: "根據文中使用地圖的步驟，下列哪一項做法最符合文章說明？", type: "mc", answer: "D. 先找自己位置與目的地，再沿街道或交通線規劃路線", choices: ["A. 不看地圖，閉著眼亂走", "B. 只看顏色，不管方向與圖例", "C. 先跑出去，回頭再猜位置", "D. 先找自己位置與目的地，再沿街道或交通線規劃路線"], explantation: ["文中寫先找所在位置與目的地，再沿街道或捷運線規劃路線"], pirlsProcess: .evaluating, difficultyLevel: 3, readingPurpose: .informational),
        
        // ========== PASSAGE 13: 爺爺的故事盒 (Literary, P3) ==========
        "q49": Question(key: "q49", question: "爺爺的舊木盒裡放了哪些東西？", type: "mc", answer: "A. 黑白照片、一枚銅鈴和一本手寫筆記", choices: ["A. 黑白照片、一枚銅鈴和一本手寫筆記", "B. 只有金銀珠寶", "C. 只有玩具汽車", "D. 空無一物"], explantation: ["文中列舉黑白照片、銅鈴與手寫筆記"], pirlsProcess: .retrieving, difficultyLevel: 3, readingPurpose: .literary),
        "q50": Question(key: "q50", question: "從故事可以推測，小晴為什麼也想把畫放進盒子？", type: "mc", answer: "B. 她希望把自己的回憶加入，讓故事繼續傳下去", choices: ["A. 她想把盒子賣掉", "B. 她希望把自己的回憶加入，讓故事繼續傳下去", "C. 她覺得盒子太輕", "D. 她不想再聽爺爺說話"], explantation: ["結尾寫她決定把畫放進去，讓故事繼續長下去"], pirlsProcess: .inferring, difficultyLevel: 3, readingPurpose: .literary),
        "q51": Question(key: "q51", question: "這個故事想告訴讀者，故事盒真正珍貴的是什麼？", type: "mc", answer: "C. 裝載的回憶與情感，而不只是金錢財物", choices: ["A. 盒子的木頭很貴", "B. 銅鈴可以換很多錢", "C. 裝載的回憶與情感，而不只是金錢財物", "D. 照片必須全部丟掉"], explantation: ["文中點明盒子裝的不是寶貝金錢，而是回憶"], pirlsProcess: .interpreting, difficultyLevel: 4, readingPurpose: .literary),
        "q52": Question(key: "q52", question: "根據爺爺分享與小晴的決定，下列哪一項判斷最有文中依據？", type: "mc", answer: "D. 透過物品說故事，能讓家人的回憶被理解和延續", choices: ["A. 小晴對爺爺的故事完全沒興趣", "B. 故事盒只適合收藏金錢", "C. 回憶不值得向晚輩分享", "D. 透過物品說故事，能讓家人的回憶被理解和延續"], explantation: ["爺爺用照片、銅鈴、筆記說故事，小晴再放入自己的畫延續，故 D 最有依據"], pirlsProcess: .evaluating, difficultyLevel: 4, readingPurpose: .literary),
        
        // ========== PASSAGE 14: 水的循環 (Informational, P3-P4) ==========
        "q53": Question(key: "q53", question: "文章中，水受熱變成水蒸氣升到空中的過程叫什麼？", type: "mc", answer: "A. 蒸發", choices: ["A. 蒸發", "B. 凝結", "C. 降水", "D. 結冰"], explantation: ["文中說明水變成水蒸氣升空叫蒸發"], pirlsProcess: .retrieving, difficultyLevel: 3, readingPurpose: .informational),
        "q54": Question(key: "q54", question: "從文中可以推測，若長時間沒有降水，對水循環最可能有什麼影響？", type: "mc", answer: "C. 河川與水資源補給減少，循環中的「回到地面」一環受阻", choices: ["A. 蒸發會立刻停止永遠不再發生", "B. 雲層會自動變成岩石", "C. 河川與水資源補給減少，循環中的「回到地面」一環受阻", "D. 海水會立刻消失"], explantation: ["降水使水回到地面並流入河川海洋；缺降水會使這一步與淡水補給受影響"], pirlsProcess: .inferring, difficultyLevel: 4, readingPurpose: .informational),
        "q55": Question(key: "q55", question: "文章描述水循環各階段，主要想說明什麼？", type: "mc", answer: "B. 水在蒸發、凝結、降水等過程中不斷移動並循環", choices: ["A. 水只用一次就消失", "B. 水在蒸發、凝結、降水等過程中不斷移動並循環", "C. 只有海洋裡才有水", "D. 植物與水循環無關"], explantation: ["全文串起蒸發、凝結、降水與回流，並提到植物也參與"], pirlsProcess: .interpreting, difficultyLevel: 4, readingPurpose: .informational),
        "q56": Question(key: "q56", question: "根據文末觀點，下列哪一項行動最能呼應文章對水循環的說明？", type: "mc", answer: "D. 了解循環後更珍惜淡水，避免浪費可用的水資源", choices: ["A. 因為水會循環，就可以任意浪費自來水", "B. 否認蒸發與降水有關", "C. 認為淡水永遠不必保護", "D. 了解循環後更珍惜淡水，避免浪費可用的水資源"], explantation: ["文末寫了解水循環能幫助珍惜淡水資源，故 D 最呼應"], pirlsProcess: .evaluating, difficultyLevel: 4, readingPurpose: .informational),
        
        // ========== PASSAGE 15: 搬家的那天 (Literary, P4) ==========
        "q57": Question(key: "q57", question: "小宇搬家前做了哪些準備？", type: "mc", answer: "A. 撕下牆上貼紙，並把窗邊盆栽包好", choices: ["A. 撕下牆上貼紙，並把窗邊盆栽包好", "B. 把家具全部丟掉", "C. 把房子拆掉", "D. 什麼都不收拾"], explantation: ["文中寫他撕貼紙並把盆栽包好"], pirlsProcess: .retrieving, difficultyLevel: 4, readingPurpose: .literary),
        "q58": Question(key: "q58", question: "從文中可以推測，小宇眼眶濕潤卻仍想到新家圖書館，代表他有什麼心情？", type: "mc", answer: "B. 不捨舊居，同時也對新環境抱有期待", choices: ["A. 只想立刻逃回家鄉，毫無其他想法", "B. 不捨舊居，同時也對新環境抱有期待", "C. 完全不在乎搬家", "D. 只生氣，不想念任何人"], explantation: ["他看著巷口遠去眼眶濕，卻想到新家有更大圖書館，可見不捨與期待並存"], pirlsProcess: .inferring, difficultyLevel: 4, readingPurpose: .literary),
        "q59": Question(key: "q59", question: "媽媽的話在故事中主要傳達什麼訊息？", type: "mc", answer: "C. 住處可改變，但關愛與新故事仍會延續", choices: ["A. 搬家後就不再需要朋友", "B. 舊家的回憶必須全部忘記", "C. 住處可改變，但關愛與新故事仍會延續", "D. 新家一定比舊家差"], explantation: ["媽媽說家會換地方，但關心的人還在，新故事也會開始"], pirlsProcess: .interpreting, difficultyLevel: 5, readingPurpose: .literary),
        "q60": Question(key: "q60", question: "根據鄰居張阿姨與小宇的反應，下列哪一項判斷最有文中依據？", type: "mc", answer: "D. 鄰里情誼能安慰離別情緒，也讓人更珍惜連結", choices: ["A. 張阿姨完全沒有來送行", "B. 小宇把餅乾盒立刻丟掉", "C. 搬家時沒有任何人關心小宇", "D. 鄰里情誼能安慰離別情緒，也讓人更珍惜連結"], explantation: ["張阿姨送手工餅乾叮囑常回來看，小宇把餅乾盒抱緊，支持 D"], pirlsProcess: .evaluating, difficultyLevel: 5, readingPurpose: .literary),
        
        // ========== PASSAGE 16: 蜜蜂與授粉 (Informational, P4-P5) ==========
        "q61": Question(key: "q61", question: "文章中，蜜蜂幫助植物結果的過程叫做什麼？", type: "mc", answer: "A. 授粉", choices: ["A. 授粉", "B. 冬眠", "C. 遷徙", "D. 光合作用"], explantation: ["文中明確稱此過程為授粉"], pirlsProcess: .retrieving, difficultyLevel: 4, readingPurpose: .informational),
        "q62": Question(key: "q62", question: "從文中可以推測，若蜜蜂數量明顯減少，最可能出現什麼情況？", type: "mc", answer: "C. 依賴昆蟲授粉的農作物收成可能受影響", choices: ["A. 所有植物立刻停止需要陽光", "B. 水果會自動變得更多", "C. 依賴昆蟲授粉的農作物收成可能受影響", "D. 授粉會改由石頭完成"], explantation: ["文中指出許多蔬果仰賴昆蟲授粉，蜜蜂減少可能影響收成"], pirlsProcess: .inferring, difficultyLevel: 5, readingPurpose: .informational),
        "q63": Question(key: "q63", question: "文章說明蜜蜂與授粉，主要想強調什麼？", type: "mc", answer: "B. 蜜蜂在生態與農業中扮演重要連結角色", choices: ["A. 蜜蜂只會製造噪音", "B. 蜜蜂在生態與農業中扮演重要連結角色", "C. 授粉與人類生活無關", "D. 不必認識昆蟲的角色"], explantation: ["全文連結採蜜、授粉、農作與保護，強調生態系統連結"], pirlsProcess: .interpreting, difficultyLevel: 5, readingPurpose: .informational),
        "q64": Question(key: "q64", question: "根據文中提出的保護方法，下列哪一項作法最能得到文章支持？", type: "mc", answer: "D. 減少有害農藥，並保留多樣蜜源與野花草地", choices: ["A. 大量噴灑對蜜蜂有害的藥劑", "B. 把所有野花草地全部清除", "C. 禁止種植任何開花植物", "D. 減少有害農藥，並保留多樣蜜源與野花草地"], explantation: ["文中列出少用有害農藥、種植蜜源植物與保留野花草地"], pirlsProcess: .evaluating, difficultyLevel: 5, readingPurpose: .informational),
        
        // ========== PASSAGE 17: 夜空下的約定 (Literary, P5-P6) ==========
        "q65": Question(key: "q65", question: "夏令營最後一晚，同學們在哪裡看星星？", type: "mc", answer: "A. 躺在草地上", choices: ["A. 躺在草地上", "B. 在地下隧道", "C. 在密閉車庫", "D. 在游泳池底"], explantation: ["文中寫同學們躺在草地上看星星"], pirlsProcess: .retrieving, difficultyLevel: 5, readingPurpose: .literary),
        "q66": Question(key: "q66", question: "從對話可以推測，阿哲起初為什麼對追夢感到猶豫？", type: "mc", answer: "B. 他擔心功課太多，恐怕沒時間", choices: ["A. 他已經當上導覽員", "B. 他擔心功課太多，恐怕沒時間", "C. 他不喜歡星星", "D. 老師禁止觀星"], explantation: ["阿哲說擔心功課太多，沒時間追夢"], pirlsProcess: .inferring, difficultyLevel: 5, readingPurpose: .literary),
        "q67": Question(key: "q67", question: "老師建議把大目標拆成小步驟，在故事中主要想表達什麼？", type: "mc", answer: "C. 持續而可行的行動，才能讓夢想不只停在當晚", choices: ["A. 夢想只能靠運氣實現", "B. 不必再做任何努力", "C. 持續而可行的行動，才能讓夢想不只停在當晚", "D. 觀星社一定會失敗"], explantation: ["老師強調每週留時間觀察或閱讀，夢想才不會只停在今晚"], pirlsProcess: .interpreting, difficultyLevel: 6, readingPurpose: .literary),
        "q68": Question(key: "q68", question: "根據兩人後來的約定，下列哪一項評價最有文中依據？", type: "mc", answer: "D. 組成觀星社並定期記錄，是把夢想落成具體行動", choices: ["A. 他們約定後立刻忘記一切", "B. 約定只是隨便說說，全無行動計畫", "C. 觀星與夢想完全無關", "D. 組成觀星社並定期記錄，是把夢想落成具體行動"], explantation: ["文中寫他們約定組成小小觀星社，每月記錄一次夜空"], pirlsProcess: .evaluating, difficultyLevel: 6, readingPurpose: .literary),
        
        // ========== PASSAGE 18: 地震安全須知 (Informational, P5-P6) ==========
        "q69": Question(key: "q69", question: "地震發生時，若在室內，文章建議首先怎麼做？", type: "mc", answer: "A. 就近躲到堅固桌子下方，雙手護住頭頸", choices: ["A. 就近躲到堅固桌子下方，雙手護住頭頸", "B. 立刻跑去靠窗看風景", "C. 爬到高高的書櫃頂上", "D. 衝去電梯快速下樓"], explantation: ["文中寫就近躲到堅固桌子下並護住頭頸，遠離玻璃窗與書櫃"], pirlsProcess: .retrieving, difficultyLevel: 5, readingPurpose: .informational),
        "q70": Question(key: "q70", question: "從文中可以推測，為什麼學校要定期舉行避難演習？", type: "mc", answer: "C. 讓正確動作變成習慣，危急時能更快反應", choices: ["A. 只是為了增加作業量", "B. 為了取消所有安全準備", "C. 讓正確動作變成習慣，危急時能更快反應", "D. 因為地震演習能阻止地震發生"], explantation: ["文中說明演習是為了讓正確動作變成習慣"], pirlsProcess: .inferring, difficultyLevel: 6, readingPurpose: .informational),
        "q71": Question(key: "q71", question: "文章同時談地震當下與平時準備，主要想說明什麼？", type: "mc", answer: "B. 冷靜應變與事前準備同樣重要，能降低受傷風險", choices: ["A. 只有地震當下需要注意，平時不必準備", "B. 冷靜應變與事前準備同樣重要，能降低受傷風險", "C. 急救包完全沒有用", "D. 疏散時愈慌亂愈好"], explantation: ["全文涵蓋當下保護、事後疏散與平時準備、演習，並總結可降低風險"], pirlsProcess: .interpreting, difficultyLevel: 6, readingPurpose: .informational),
        "q72": Question(key: "q72", question: "根據文中安全步驟，下列哪一項家庭準備最能得到文章支持？", type: "mc", answer: "D. 準備急救包與飲用水，並事先約定集合地點", choices: ["A. 地震時先去靠近玻璃窗", "B. 平時完全不討論集合地點", "C. 震動一停就搭電梯下樓看熱鬧", "D. 準備急救包與飲用水，並事先約定集合地點"], explantation: ["文中建議準備急救包、手電筒與飲用水，並約定集合地點"], pirlsProcess: .evaluating, difficultyLevel: 6, readingPurpose: .informational)
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
    
    /// Stable offline catalog of local passage sets (sorted by `passageKey`).
    func getAllPassageSets() -> [PassageQuestionSet] {
        passageSets.values.sorted { $0.passageKey < $1.passageKey }
    }
    
    func getAllPassageKeys() -> [String] {
        getAllPassageSets().map { $0.passageKey }
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
    ),
    
    // ========== PASSAGE 10: 阿美的雨天日記 (Literary, P1) ==========
    "p10": PassageQuestionSet(
        passageKey: "passage10",
        passage: """
        阿美早上醒來，看見窗外下著細雨。她本來想去公園玩，但媽媽說雨天可以在家做有趣的事。\n阿美找出彩色筆和空白本子，畫下雨滴敲打窗戶的樣子。下午，她和弟弟一起用紙盒做了一艘小船，放在陽台接雨水的盆子裡漂浮。\n傍晚雨停了，天空出現淡淡彩虹。阿美在日記寫下：雨天不一定掃興，只要換個方式，也能過得很開心。
        """,
        questionKeys: ["q37", "q38", "q39", "q40"]
    ),
    
    // ========== PASSAGE 11: 操場上的接力賽 (Literary, P2) ==========
    "p11": PassageQuestionSet(
        passageKey: "passage11",
        passage: """
        星期五下午，三年甲班和三年乙班舉行接力賽。小傑接到棒子時差點跌倒，卻立刻站穩繼續跑。\n最後一棒的小華奮力衝過終點，甲班只贏了兩步。乙班同學雖然輸了，仍為對手鼓掌。\n老師說：「輸贏重要，但更重要的是彼此加油、不放棄。」小傑摸摸膝蓋，笑著說下次會跑得更穩。
        """,
        questionKeys: ["q41", "q42", "q43", "q44"]
    ),
    
    // ========== PASSAGE 12: 認識地圖與方向 (Informational, P2-P3) ==========
    "p12": PassageQuestionSet(
        passageKey: "passage12",
        passage: """
        地圖可以幫助我們找到方向。地圖上方通常代表北方，下方是南方，左西右東。\n圖例用符號標示學校、公園、車站。比例尺告訴我們圖上距離和實際距離的關係。\n使用地圖時，先找到自己所在位置，再找出目的地，沿著街道或捷運線規劃路線。學會看地圖，外出就不容易迷路。
        """,
        questionKeys: ["q45", "q46", "q47", "q48"]
    ),
    
    // ========== PASSAGE 13: 爺爺的故事盒 (Literary, P3) ==========
    "p13": PassageQuestionSet(
        passageKey: "passage13",
        passage: """
        爺爺有一個舊木盒，裡面放著黑白照片、一枚銅鈴和一本手寫筆記。每到週末，孫女小晴就央求爺爺打開故事盒。\n爺爺指著照片說那是他小時住過的街巷；搖一搖銅鈴，說那是廟會時買的；翻開筆記，讀出當年學寫字的句子。\n小晴發現，故事盒裡裝的不是寶貝金錢，而是回憶。她決定把自己畫的畫也放進去，讓故事繼續長下去。
        """,
        questionKeys: ["q49", "q50", "q51", "q52"]
    ),
    
    // ========== PASSAGE 14: 水的循環 (Informational, P3-P4) ==========
    "p14": PassageQuestionSet(
        passageKey: "passage14",
        passage: """
        地球上的水不斷循環。陽光加熱海洋與湖泊，水變成水蒸氣升到空中，這叫蒸發。水蒸氣遇冷凝結成小水滴，聚成雲，這叫凝結。\n水滴夠大就落下成為雨或雪，稱為降水。雨水流入河川，再回到海洋，循環重新開始。植物也會透過葉子釋放水氣，幫助循環。\n了解水循環，能幫助我們珍惜淡水資源。
        """,
        questionKeys: ["q53", "q54", "q55", "q56"]
    ),
    
    // ========== PASSAGE 15: 搬家的那天 (Literary, P4) ==========
    "p15": PassageQuestionSet(
        passageKey: "passage15",
        passage: """
        小宇要從住了八年的舊公寓搬走。他把牆上的貼紙慢慢撕下，又把窗邊的小盆栽包好。鄰居張阿姨送來一盒手工餅乾，叮囑他常回來看。\n貨車開動時，小宇看著熟悉的巷口漸漸遠去，眼眶有點濕，卻也想到新家附近有更大的圖書館。\n媽媽握住他的手說：「家會換地方，但關心我們的人還在，新的故事也會開始。」小宇點點頭，把餅乾盒抱得更緊。
        """,
        questionKeys: ["q57", "q58", "q59", "q60"]
    ),
    
    // ========== PASSAGE 16: 蜜蜂與授粉 (Informational, P4-P5) ==========
    "p16": PassageQuestionSet(
        passageKey: "passage16",
        passage: """
        蜜蜂在花叢間採蜜時，身上會沾上花粉。當牠飛到另一朵花，花粉就可能落到雌蕊上，幫助植物結果，這個過程叫做授粉。\n許多水果和蔬菜都仰賴昆蟲授粉。若蜜蜂數量減少，農作物收成可能受影響。保護蜜蜂的方法包括少用有害農藥、種植多樣蜜源植物，以及保留野花草地。\n認識蜜蜂的角色，能讓我們更懂生態系統的連結。
        """,
        questionKeys: ["q61", "q62", "q63", "q64"]
    ),
    
    // ========== PASSAGE 17: 夜空下的約定 (Literary, P5-P6) ==========
    "p17": PassageQuestionSet(
        passageKey: "passage17",
        passage: """
        夏令營最後一晚，同學們躺在草地上看星星。嚮導指出北斗七星，又說明有些光點其實是行星。\n小安忽然說自己以後想當天文導覽員；旁邊的阿哲卻擔心功課太多，沒時間追夢。老師接話：「把大目標拆成小步驟，每週留一點時間觀察或閱讀，夢想才不會只停在今晚。」\n兩人約定回學校後組成小小觀星社，每月記錄一次夜空。蟲鳴聲中，約定像一顆剛點亮的星。
        """,
        questionKeys: ["q65", "q66", "q67", "q68"]
    ),
    
    // ========== PASSAGE 18: 地震安全須知 (Informational, P5-P6) ==========
    "p18": PassageQuestionSet(
        passageKey: "passage18",
        passage: """
        地震發生時，最重要的是保持冷靜並快速保護自己。若在室內，應就近躲到堅固桌子下方，雙手護住頭頸，並遠離玻璃窗與書櫃。地震停止後，再依指示有秩序地疏散到空曠安全處。\n平時可在家中準備急救包、手電筒與飲用水，並和家人約定集合地點。學校定期舉行避難演習，是為了讓正確動作變成習慣。掌握這些步驟，能在危急時刻降低受傷風險。
        """,
        questionKeys: ["q69", "q70", "q71", "q72"]
    )
]
