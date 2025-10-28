import SwiftUI

struct Question1: Codable {
    let questionText: String
    let options: [String]
    let correctAnswer: String
}

struct ContentView: View {
    @State private var questions1: [Question1] = []
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var lives = 3
    @State private var gameOver = false
    @State private var isLoading = true
    @State private var errorMessage: String?

    let serverURL = "https://your-alibaba-cloud-server.com"  // Replace with your Alibaba Cloud API

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("加載問題中...")
            } else if let errorMessage = errorMessage {
                Text("錯誤: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
                Button("重試") {
                    fetchQuestions()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else if gameOver {
                VStack {
                    Text("遊戲結束！")
                        .font(.largeTitle)
                        .padding()
                    Text("你的得分：\(score)")
                        .font(.title)
                        .padding()
                    Button("重新開始") {
                        restartGame()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                Text("詞語迷宮")
                    .font(.largeTitle)
                    .padding()
                
                Text("生命值: \(lives) ❤️")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("得分: \(score)")
                    .font(.title2)
                    .padding()
                
                let question1 = questions1[currentQuestionIndex]
                Text(question1.questionText)
                    .font(.title2)
                    .padding()
                
                ForEach(question1.options, id: \.self) { option in
                    Button(action: {
                        checkAnswer(option)
                    }) {
                        Text(option)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .font(.title3)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .onAppear {
            fetchQuestions()
        }
    }

    // Fetch questions from Alibaba Cloud server
    func fetchQuestions() {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(serverURL)/get-questions") else {
            errorMessage = "無效的伺服器 URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "加載問題失敗: \(error.localizedDescription)"
                    isLoading = false
                    return
                }

                guard let data = data else {
                    errorMessage = "未獲取數據"
                    isLoading = false
                    return
                }

                do {
                    let fetchedQuestions = try JSONDecoder().decode([Question1].self, from: data)
                    if fetchedQuestions.isEmpty {
                        errorMessage = "未獲取任何問題"
                    } else {
                        questions1 = fetchedQuestions
                        currentQuestionIndex = 0
                        score = 0
                        lives = 3
                        gameOver = false
                    }
                } catch {
                    errorMessage = "數據解析失敗"
                }
                isLoading = false
            }
        }.resume()
    }

    // Check answer and handle game logic
    func checkAnswer(_ selectedAnswer: String) {
        let correctAnswer = questions1[currentQuestionIndex].correctAnswer
        if selectedAnswer == correctAnswer {
            score += 10
        } else {
            lives -= 1
            if lives == 0 {
                gameOver = true
                sendResultsToServer()
                return
            }
        }

        if currentQuestionIndex < questions1.count - 1 {
            currentQuestionIndex += 1
        } else {
            gameOver = true
            sendResultsToServer()
        }
    }

    // Send game results to the server
    func sendResultsToServer() {
        guard let url = URL(string: "\(serverURL)/submit-results") else { return }
        let results: [String: Any] = [
            "score": score,
            "livesLeft": lives
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: results) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("結果提交失敗: \(error.localizedDescription)")
                return
            }
            print("結果提交成功")
        }.resume()
    }

    // Restart the game and fetch new questions
    func restartGame() {
        fetchQuestions()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
